# frozen_string_literal: true

class Folio::CraMediaCloud::CreateMediaJob < Folio::ApplicationJob
  # Discard if file no longer exists
  discard_on ActiveJob::DeserializationError

  queue_as :default

  def perform(media_file)
    fail "only video files are supported" unless media_file.is_a?(Folio::File::Video)

    # Generate reference_id based on current file content
    current_reference_id = generate_reference_id(media_file)

    # Check API for existing job with this reference_id
    existing_job_result = check_existing_job(current_reference_id, media_file)

    case existing_job_result[:status]
    when :processing
      Rails.logger.info "[CraMediaCloud::CreateMediaJob] Video #{media_file.id} (#{current_reference_id}) already processing, skipping upload"
      return
    when :done
      Rails.logger.info "[CraMediaCloud::CreateMediaJob] Video #{media_file.id} (#{current_reference_id}) already done, updating local state if needed"
      update_local_state_for_successful_job(media_file, existing_job_result[:job], current_reference_id)
      return
    when :failed, :not_found
      Rails.logger.info "[CraMediaCloud::CreateMediaJob] Video #{media_file.id} (#{current_reference_id}) needs processing (status: #{existing_job_result[:status]})"
      # Proceed with upload
    end

    # Upload the file
    process_media_upload(media_file, current_reference_id)
  end

  private
    def generate_reference_id(media_file)
      # Combine video slug with S3 ETag (actual file content MD5) for stable, unique reference
      # Format: {slug}-{s3_etag}
      # This ensures uniqueness across environments and file versions
      s3_etag = get_s3_etag(media_file)

      "#{media_file.slug}-#{s3_etag[0..7]}"
    end

    def get_s3_etag(media_file)
      # Get S3 ETag (MD5 hash) without downloading the file
      s3_metadata = get_s3_metadata(media_file)
      extract_etag(s3_metadata).delete_prefix('"').delete_suffix('"')
    end

    def get_s3_metadata(media_file)
      s3_datastore = Dragonfly.app.datastore
      s3_object_key = [s3_datastore.root_path, media_file.file_uid].join("/")
      Rails.logger.debug("[CraMediaCloud::CreateMediaJob] Fetching S3 metadata for key: #{s3_object_key}")
      s3_datastore.storage.head_object(ENV["S3_BUCKET_NAME"], s3_object_key)
    end

    def extract_etag(response)
      # Handle different response types (AWS SDK, Excon, etc.)
      if response.respond_to?(:etag)
        response.etag
      elsif response.respond_to?(:headers)
        response.headers["ETag"] || response.headers["etag"] || response.headers["Etag"]
      else
        raise "Cannot extract ETag from response type: #{response.class}"
      end
    end

    def check_existing_job(reference_id, media_file)
      api = Folio::CraMediaCloud::Api.new
      jobs = api.get_jobs(ref_id: reference_id)

      if jobs.empty?
        { status: :not_found, job: nil }
      else
        # Get the most recent job with this reference_id by lastModified
        job = jobs.max_by { |j| Time.parse(j["lastModified"]) }
        Rails.logger.debug "[CraMediaCloud::CreateMediaJob] Found #{jobs.size} job(s) for #{reference_id}, using most recent from #{job['lastModified']}"

        case job["status"]
        when "PROCESSING", "CREATED"
          { status: :processing, job: job }
        when "DONE"
          { status: :done, job: job }
        when "FAILED", "ERROR"
          { status: :failed, job: job }
        else
          { status: :not_found, job: job }
        end
      end
    rescue => e
      Rails.logger.warn "[CraMediaCloud::CreateMediaJob] Could not check existing job for #{reference_id}: #{e.message}"
      { status: :not_found, job: nil } # Assume not found if API call fails
    end

    def update_local_state_for_successful_job(media_file, job, reference_id)
      # Check if local state needs updating
      current_remote_id = media_file.remote_services_data["remote_id"]
      successful_job_id = job["id"]

      if current_remote_id != successful_job_id
        Rails.logger.info "[CraMediaCloud::CreateMediaJob] Updating local state: remote_id #{current_remote_id} -> #{successful_job_id} for video #{media_file.id}"

        # Capture encoding_generation before updating state
        current_generation = media_file.encoding_generation

        # Update local state to point to the successful job
        media_file.remote_services_data.merge!({
          "service" => "cra_media_cloud",
          "reference_id" => reference_id,
          "remote_id" => successful_job_id,
          "processing_state" => "full_media_processing", # Will be updated by CheckProgressJob
          "processing_step_started_at" => Time.current.iso8601
        })
        media_file.save!

        # Schedule CheckProgressJob to update final state based on the successful job
        # Pass encoding_generation so it can detect if it becomes stale
        Folio::CraMediaCloud::CheckProgressJob.perform_later(
          media_file,
          encoding_generation: current_generation
        )

        broadcast_file_update(media_file)

        Rails.logger.info "[CraMediaCloud::CreateMediaJob] Successfully updated local state for video #{media_file.id} to point to successful job #{successful_job_id}"
      else
        Rails.logger.debug "[CraMediaCloud::CreateMediaJob] Local state already points to correct job #{successful_job_id} for video #{media_file.id}"
      end
    end

    def process_media_upload(media_file, reference_id)
      # Capture encoding_generation before any state updates
      current_generation = media_file.encoding_generation

      # Set state to creating_media_job before starting upload
      rs_data = media_file.remote_services_data || {}
      media_file.remote_services_data = rs_data.merge({
        "service" => "cra_media_cloud",
        "processing_state" => "creating_media_job",
        "processing_step_started_at" => Time.current.iso8601
      })
      media_file.save!

      Rails.logger.info "[CraMediaCloud::CreateMediaJob] Starting upload for video #{media_file.id} with reference_id: #{reference_id}"

      begin
        Folio::CraMediaCloud::Encoder.new.upload_file(
          media_file,
          profile_group: media_file.try(:encoder_profile_group),
          reference_id: reference_id
        )

        # Update to processing state after successful upload
        media_file.remote_services_data.merge!({
          "reference_id" => reference_id,
          "processing_state" => "full_media_processing",
          "processing_step_started_at" => Time.current.iso8601
        })
        # Clear any old remote_id since we're starting fresh
        media_file.remote_services_data.delete("remote_id")
        media_file.save!

        # Pass encoding_generation so CheckProgressJob can detect stale jobs
        Folio::CraMediaCloud::CheckProgressJob.set(wait: 30.seconds).perform_later(
          media_file,
          encoding_generation: current_generation
        )

        broadcast_file_update(media_file)

        Rails.logger.info "[CraMediaCloud::CreateMediaJob] Successfully uploaded video #{media_file.id} with reference_id: #{reference_id}"
      rescue => e
        # Reset state on error to allow future retries
        Rails.logger.error "[CraMediaCloud::CreateMediaJob] Upload failed for video #{media_file.id}: #{e.message}"

        media_file.remote_services_data.merge!({
          "processing_state" => "upload_failed",
          "error_message" => e.message,
          "processing_step_started_at" => Time.current.iso8601
        })
        media_file.save!

        broadcast_file_update(media_file)
        raise e
      end
    end
end

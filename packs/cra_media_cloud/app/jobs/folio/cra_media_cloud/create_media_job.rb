# frozen_string_literal: true

class Folio::CraMediaCloud::CreateMediaJob < Folio::ApplicationJob
  include Folio::S3::Client

  # Discard if file no longer exists
  discard_on ActiveJob::DeserializationError

  queue_as :default

  def perform(media_file)
    fail "only video files are supported" unless media_file.is_a?(Folio::File::Video)

    # If retrying after failure, transition back to processing
    if media_file.processing_failed? && media_file.remote_services_data&.dig("retry_count").to_i > 0
      media_file.retry_processing!
      Rails.logger.info "[CraMediaCloud::CreateMediaJob] Video #{media_file.id} retrying after failure"
    end

    # Generate reference_id based on current file content.
    # If the source file no longer exists on S3, mark as permanently failed
    # and don't retry — the file cannot be re-uploaded without the original.
    begin
      current_reference_id = generate_reference_id(media_file)
    rescue Excon::Error::NotFound => e
      Rails.logger.error "[CraMediaCloud::CreateMediaJob] Source file not found on S3 for video #{media_file.id}: #{e.message}"
      mark_source_file_missing!(media_file)
      return
    end

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
      # Combine environment, video slug, ID, S3 ETag, and encoding_generation for unique reference.
      # ID guarantees uniqueness per video record (slug alone is derived from filename and can collide).
      # encoding_generation changes on each re-encode, ensuring CRA gets a fresh refId.
      # Format: {env}-{slug}-{id}-{s3_etag}-{generation}
      # Total length is capped at 128 chars to avoid CRA lookup failures with long slugs.
      s3_etag = get_s3_etag(media_file)
      env_prefix = ENV.fetch("DRAGONFLY_RAILS_ENV", Rails.env)
      generation = media_file.encoding_generation

      if generation.nil?
        # encoding_generation may not be visible yet if the enclosing transaction
        # (e.g. S3::CreateFileJob save) hasn't committed. Reload to get committed data.
        media_file.reload
        generation = media_file.encoding_generation
      end

      if generation.nil?
        fail "encoding_generation not set for video #{media_file.id} — cannot generate unique reference_id (would match stale CRA jobs)"
      end

      suffix = "-#{media_file.id}-#{s3_etag[0..7]}-#{generation}"
      max_slug_length = 128 - env_prefix.length - 1 - suffix.length
      slug = media_file.slug.to_s[0, [max_slug_length, 1].max]

      "#{env_prefix}-#{slug}#{suffix}"
    end

    def get_s3_etag(media_file)
      s3_metadata = s3_dragonfly_head_object(media_file.file_uid)
      extract_s3_etag(s3_metadata).delete_prefix('"').delete_suffix('"')
    end

    def check_existing_job(reference_id, media_file)
      api = Folio::CraMediaCloud::Api.new
      jobs = api.get_jobs(ref_id: reference_id)

      # No need to pre-filter REMOVED jobs: JobResolver maps REMOVED → :not_found,
      # so CreateMediaJob will proceed with a fresh upload. (MonitorProcessingJob
      # pre-filters REMOVED before passing to reconcile_with_remote_jobs because it
      # needs to distinguish "all REMOVED with stored phase data → finalize" from
      # "no jobs at all → clear state". CreateMediaJob has no such distinction to make.)
      result = Folio::CraMediaCloud::JobResolver.resolve(jobs)

      Rails.logger.debug "[CraMediaCloud::CreateMediaJob] Job check for #{reference_id}: " \
                          "#{jobs.size} job(s), status=#{result[:status]}"

      result
    rescue => e
      Rails.logger.warn "[CraMediaCloud::CreateMediaJob] Could not check existing job for #{reference_id}: #{e.message}"
      { status: :not_found, job: nil }
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
        # remote_id already matches, but if local processing_state is stale (e.g. upload_failed
        # or encoding_failed set before CRA recovered), schedule CheckProgressJob to finalize.
        # This handles videos that got stuck with a failed state while the CRA job eventually
        # completed successfully on CRA's side.
        if media_file.remote_services_data["processing_state"] != "full_media_processed"
          media_file.remote_services_data.merge!(
            "processing_state" => "full_media_processing",
            "processing_step_started_at" => Time.current.iso8601
          )
          media_file.save!
          Folio::CraMediaCloud::CheckProgressJob.perform_later(
            media_file,
            encoding_generation: media_file.encoding_generation
          )
          Rails.logger.info "[CraMediaCloud::CreateMediaJob] Remote ID #{successful_job_id} matches but state " \
                            "was stale (#{media_file.remote_services_data['processing_state']}), " \
                            "scheduling CheckProgressJob for video #{media_file.id}"
        else
          Rails.logger.debug "[CraMediaCloud::CreateMediaJob] Local state already points to correct job #{successful_job_id} for video #{media_file.id}"
        end
      end
    end

    def process_media_upload(media_file, reference_id)
      # Capture encoding_generation before any state updates
      current_generation = media_file.encoding_generation
      profile_group = media_file.try(:encoder_profile_group)

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
        processing_phases = media_file.try(:encoder_processing_phases)
        encoder = Folio::CraMediaCloud::Encoder.new

        encoder.upload_file(
          media_file,
          profile_group: profile_group,
          processing_phases: processing_phases,
          reference_id: reference_id
        )

        media_file.remote_services_data.merge!({
          "reference_id" => reference_id,
          "processing_state" => "full_media_processing",
          "processing_step_started_at" => Time.current.iso8601,
          "processing_phases" => processing_phases.to_i > 1 ? processing_phases : nil,
        })

        # Clear any old remote_id since we're starting fresh
        media_file.remote_services_data.delete("remote_id")
        media_file.save!

        # Pass encoding_generation so CheckProgressJob can detect stale jobs
        Folio::CraMediaCloud::CheckProgressJob.set(wait: 10.seconds).perform_later(
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

    def mark_source_file_missing!(media_file)
      rs_data = media_file.remote_services_data || {}
      rs_data.merge!({
        "service" => "cra_media_cloud",
        "processing_state" => "source_file_missing",
        "error_message" => "Source file not found on S3 (file_uid: #{media_file.file_uid})",
        "processing_step_started_at" => Time.current.iso8601,
      })
      media_file.remote_services_data = rs_data

      begin
        media_file.processing_failed!
      rescue => e
        Rails.logger.warn "[CraMediaCloud::CreateMediaJob] AASM transition failed for video #{media_file.id} (#{e.message}), forcing state"
        media_file.update_columns(aasm_state: "processing_failed", remote_services_data: rs_data, updated_at: Time.current)
      end

      broadcast_file_update(media_file)
    end
end

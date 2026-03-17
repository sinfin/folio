# frozen_string_literal: true

class Folio::CraMediaCloud::CheckProgressJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError

  queue_as :default

  unique :until_and_while_executing

  # Maximum time to poll CRA before giving up (4 hours).
  # Long videos can take 2+ hours for HD encoding across multiple phases.
  MAX_PROCESSING_DURATION = 4.hours

  attr_reader :media_file

  def perform(media_file, preview: false, encoding_generation: nil)
    @media_file = media_file
    @encoding_generation = encoding_generation

    if @encoding_generation.present? && media_file.encoding_generation != @encoding_generation
      Rails.logger.info "[CraMediaCloud::CheckProgressJob] Skipping stale job for #{media_file.class.name}##{media_file.id} " \
                        "(job generation: #{@encoding_generation}, current: #{media_file.encoding_generation})"
      return
    end

    if media_file.ready?
      Rails.logger.info "[CraMediaCloud::CheckProgressJob] Video #{media_file.id} is already in ready state"
      return
    end

    if processing_timed_out?
      Rails.logger.error "[CraMediaCloud::CheckProgressJob] Timed out after #{MAX_PROCESSING_DURATION.inspect} " \
                         "for video #{media_file.id}. Marking as processing_failed."
      if media_file.may_processing_failed?
        # No with_lock here: timeout is a one-time terminal state written only by
        # this code path. CheckProgressJob is unique-constrained so no concurrent
        # instance runs. Broadcasts immediately follow the DB write intentionally.
        media_file.processing_failed!
        broadcast_file_update(media_file)
        broadcast_encoding_progress
      end
      return
    end

    check_progress
  end

  private
    def multi_phase?
      media_file.remote_services_data["processing_phases"].to_i > 1
    end

    def expected_phases
      media_file.remote_services_data["processing_phases"].to_i
    end

    def check_progress
      response = fetch_job_response
      return if response == :finalized # already handled by finalize_from_completed_phases!
      return check_again_later if response.nil?

      # Terminal state: CRA has cleaned up this job.
      # Only stop polling if we were tracking a specific job (remote_id present).
      # If we don't have remote_id yet, this is a stale job from a previous run — keep waiting.
      if response["status"] == "REMOVED"
        if media_file.remote_id.present?
          Rails.logger.warn "[CraMediaCloud::CheckProgressJob] Job #{response['id']} for video #{media_file.id} " \
                            "has been REMOVED by CRA. Stopping progress check."
          return
        else
          Rails.logger.info "[CraMediaCloud::CheckProgressJob] Found REMOVED job #{response['id']} for video #{media_file.id} " \
                            "but no remote_id tracked yet — waiting for new job"
          return check_again_later
        end
      end

      # Broadcasts are emitted after the lock is released to avoid holding
      # the Postgres row lock while doing Redis I/O.
      should_broadcast = false

      media_file.with_lock do
        update_remote_service_data(response)

        if media_file.full_media_processed?
          media_file.processing_done!
          should_broadcast = true
        elsif media_file.processing_failed?
          should_broadcast = true # state set by handle_job_failure; broadcast below
        elsif media_file.changed?
          media_file.save!
          should_broadcast = true
          check_again_later
        else
          check_again_later
        end
      end

      if should_broadcast
        broadcast_file_update(media_file)
        broadcast_encoding_progress
      end
    end

    def fetch_job_response
      if media_file.remote_id.present?
        response = api.get_job(media_file.remote_id)
        Rails.logger.info "[CraMediaCloud::CheckProgressJob] Job #{media_file.remote_id} for video #{media_file.id}: " \
                          "status=#{response&.dig('status')}, progress=#{response&.dig('progress')}, " \
                          "profileGroup=#{response&.dig('profileGroup')}, phase=#{response&.dig('phase')}"

        # Multi-phase: if the tracked job is DONE but not the final phase,
        # save intermediate data, clear remote_id, and look up by reference_id.
        # Intermediate save is wrapped in with_lock to protect against concurrent
        # MonitorProcessingJob or retry CreateMediaJob runs.
        if multi_phase? && response&.dig("status") == "DONE" && response&.dig("phase").to_i < expected_phases
          media_file.with_lock do
            save_intermediate_phase_data(response)
            media_file.remote_services_data.delete("remote_id")
            media_file.save!
          end
          broadcast_encoding_progress
          broadcast_file_update(media_file)
          Rails.logger.info "[CraMediaCloud::CheckProgressJob] Phase #{response['phase']} done, cleared remote_id to discover next phase"
          return nil
        end

        response
      elsif media_file.remote_reference_id.present?
        all_jobs = api.get_jobs(ref_id: media_file.remote_reference_id)
        # Filter out REMOVED jobs — these are old completed jobs cleaned up by CRA
        jobs = all_jobs.reject { |j| j["status"] == "REMOVED" }
        if jobs.empty?
          # If we already have completed phase data and all jobs are REMOVED,
          # CRA has cleaned up and no further phases are coming — mark as done.
          if multi_phase? && all_jobs.present? && has_any_completed_phase?
            Rails.logger.info "[CraMediaCloud::CheckProgressJob] All CRA jobs REMOVED for video #{media_file.id} " \
                              "with completed phase data. Finalizing from stored phase output."
            finalize_from_completed_phases!
            return :finalized
          end

          Rails.logger.info "[CraMediaCloud::CheckProgressJob] No active jobs found for reference_id #{media_file.remote_reference_id} " \
                            "(video #{media_file.id}, #{all_jobs.size} removed) — CRA may still be downloading the file"
          return nil
        end
        if multi_phase?
          select_multi_phase_job(jobs)
        else
          job = jobs.max_by { |j| Time.parse(j["lastModified"]) }
          Rails.logger.info "[CraMediaCloud::CheckProgressJob] Found #{jobs.size} job(s) for #{media_file.remote_reference_id} (video #{media_file.id}): " \
                            "status=#{job['status']}, progress=#{job['progress']}, id=#{job['id']}, " \
                            "profileGroup=#{job['profileGroup']}, lastModified=#{job['lastModified']}"
          job
        end
      else
        Rails.logger.info "[CraMediaCloud::CheckProgressJob] No remote_id or remote_reference_id for #{media_file.class.name} ID #{media_file.id}"
        nil
      end
    end

    def select_multi_phase_job(jobs)
      # Sort by phase descending, pick the highest-phase job
      job = jobs.sort_by { |j| -(j["phase"].to_i) }.first

      phase = job["phase"].to_i
      Rails.logger.debug "[CraMediaCloud::CheckProgressJob] Multi-phase: found #{jobs.size} job(s), highest phase=#{phase}/#{expected_phases}, status=#{job['status']}"

      # If the highest-phase job is DONE but we haven't reached the final phase,
      # check if CRA created a next phase job. CRA creates all phase jobs upfront —
      # if no higher phase exists by now, CRA decided this is the final output.
      if job["status"] == "DONE" && phase < expected_phases
        next_phase_exists = jobs.any? { |j| j["phase"].to_i > phase }

        if next_phase_exists
          # Next phase job exists but hasn't surpassed the current one yet — wait.
          # Lock to guard against concurrent MonitorProcessingJob runs.
          media_file.with_lock do
            unless media_file.remote_services_data["phase_#{phase}_completed_at"].present?
              save_intermediate_phase_data(job)
            end
          end
          return nil
        else
          # CRA did not create further phases — treat this as the final output
          Rails.logger.info "[CraMediaCloud::CheckProgressJob] CRA created no phase #{phase + 1} job for video #{media_file.id}. " \
                            "Treating phase #{phase} output as final."
          return job
        end
      end

      job
    end

    def has_any_completed_phase?
      (1..expected_phases).any? { |p| media_file.remote_services_data["phase_#{p}_completed_at"].present? }
    end

    # When all CRA jobs are REMOVED but we have stored phase output data,
    # finalize the video using the last completed phase's output.
    def finalize_from_completed_phases!
      last_phase = (1..expected_phases).reverse_each.find { |p|
        media_file.remote_services_data["phase_#{p}_completed_at"].present?
      }

      media_file.with_lock do
        # Build content_mp4_paths from all completed phases
        content_mp4_paths = {}
        (1..last_phase).each do |p|
          phase_paths = media_file.remote_services_data["phase_#{p}_content_mp4_paths"]
          content_mp4_paths.merge!(phase_paths) if phase_paths.present?
        end

        media_file.remote_services_data.merge!(
          "content_mp4_paths" => content_mp4_paths,
          "processing_state" => "full_media_processed",
          "progress_percentage" => 100.0,
          "encoding_completed_at" => Time.current.iso8601,
        )

        media_file.processing_done!
      end

      # Broadcasts after lock release to avoid Redis I/O while holding a Postgres row lock.
      broadcast_file_update(media_file)
      broadcast_encoding_progress

      Rails.logger.info "[CraMediaCloud::CheckProgressJob] Video #{media_file.id} finalized from #{last_phase} completed phase(s)"
    end

    def save_intermediate_phase_data(phase_job)
      phase_num = phase_job["phase"].to_i
      mp4_paths = {}
      manifest_hls = nil
      manifest_dash = nil

      phase_job["output"]&.each do |output_file|
        case output_file["type"]
        when "MP4"
          mp4_paths[output_file["profiles"].first] = output_file["path"]
        when "HLS"
          manifest_hls = select_output_file(manifest_hls, output_file)
        when "DASH"
          manifest_dash = select_output_file(manifest_dash, output_file)
        when "THUMBNAILS"
          update_thumbnail_path(output_file)
        end
      end

      updates = {
        "phase_#{phase_num}_content_mp4_paths" => mp4_paths,
        "phase_#{phase_num}_completed_at" => Time.current.iso8601,
        "phase_#{phase_num}_remote_id" => phase_job["id"],
      }
      updates["manifest_hls_path"] = manifest_hls["path"] if manifest_hls
      updates["manifest_dash_path"] = manifest_dash["path"] if manifest_dash

      media_file.remote_services_data.merge!(updates)
      media_file.save!

      Rails.logger.info "[CraMediaCloud::CheckProgressJob] Phase #{phase_num}/#{expected_phases} complete for video #{media_file.id}, " \
                        "saved #{mp4_paths.size} MP4 paths" \
                        "#{manifest_hls ? ', HLS manifest' : ''}" \
                        "#{manifest_dash ? ', DASH manifest' : ''}."
    end

    def update_remote_service_data(response)
      media_file.remote_services_data["remote_id"] ||= response["id"]

      case response["status"]
      when "DONE"
        process_output_hash(response["output"])
        parse_encoding_messages(response)

        media_file.remote_services_data.merge!(
          "output" => response["output"],
          "processing_state" => "full_media_processed",
          "progress_percentage" => 100.0,
          "encoding_completed_at" => Time.current.iso8601,
        )
      when "WAITING", "PROCESSING", "CREATED", "VALIDATING"
        update_progress(response)
      when "FAILED", "ERROR"
        handle_job_failure(response)
      end
    end

    def update_progress(response)
      return unless response

      media_file.remote_services_data["remote_id"] ||= response["id"]
      media_file.remote_services_data["cra_status"] = response["status"]
      media_file.remote_services_data["last_progress_check_at"] = Time.current.iso8601

      raw_progress = response["progress"].to_f
      media_file.remote_services_data["cra_raw_progress"] = raw_progress

      parse_encoding_messages(response)

      phase = current_phase(response)
      media_file.remote_services_data["current_phase"] = phase

      if multi_phase? && response["phase"].to_i > 0
        media_file.remote_services_data["current_encoding_phase"] = response["phase"].to_i
      end

      media_file.remote_services_data["progress_percentage"] = phase == "encoding" ? (raw_progress * 100).round(0) : nil
    end

    # Derive current phase from CRA status and completed message phases.
    def current_phase(response)
      case response["status"]
      when "WAITING", "CREATED", "VALIDATING"
        "waiting"
      when "PROCESSING"
        phases = media_file.remote_services_data["phases_completed"] || []
        phases.include?("video") ? "packaging" : "encoding"
      end
    end

    def handle_job_failure(response)
      error_messages = response["messages"]&.filter_map { |msg| msg["message"] if msg["type"] == "ERROR" }&.join("; ")
      retry_count = (media_file.remote_services_data["retry_count"] || 0) + 1
      will_retry = retry_count <= 1

      media_file.remote_services_data.merge!(
        "processing_state" => "encoding_failed",
        "error_message" => error_messages || "Encoding failed",
        "failed_at" => Time.current.iso8601,
        "progress_percentage" => nil,
        "current_phase" => nil,
        "retry_count" => retry_count,
      )

      if will_retry
        media_file.remote_services_data["retry_scheduled_at"] = (Time.current + 2.minutes).iso8601
      else
        media_file.remote_services_data.delete("retry_scheduled_at")
      end

      # Single save via processing_failed! — all data merged above.
      # Broadcasts are emitted by check_progress after with_lock returns.
      media_file.processing_failed!

      if will_retry
        Folio::CraMediaCloud::CreateMediaJob.set(wait: 2.minutes).perform_later(media_file)
        Rails.logger.warn "[CraMediaCloud::CheckProgressJob] Video #{media_file.id} failed (attempt #{retry_count}), scheduling retry in 2 minutes: #{error_messages}"
      else
        Rails.logger.error "[CraMediaCloud::CheckProgressJob] Video #{media_file.id} failed permanently (attempt #{retry_count}): #{error_messages}"
      end
    end

    def parse_encoding_messages(response)
      messages = response["messages"]
      return unless messages.present?

      phases_completed = []
      messages.each do |msg|
        text = msg["message"].to_s
        phases_completed << "validation" if text.include?("verification: finished")
        phases_completed << "audio" if text.include?("Transcoding worker - audio: finished")
        phases_completed << "thumbnails" if text.include?("Transcoding worker - thumbnails: finished")
        phases_completed << "video" if text.include?("Transcoding worker - video: finished")
        phases_completed << "packaging" if text.include?("copying: started")
      end

      # Extract video duration from outputParams
      video_duration = response.dig("outputParams", "duration")

      media_file.remote_services_data["phases_completed"] = phases_completed.uniq
      media_file.remote_services_data["video_duration"] = video_duration if video_duration
    end

    def process_output_hash(output_data)
      content_mp4_paths = media_file.remote_services_data["content_mp4_paths"] || {}
      manifest_hls = nil
      manifest_dash = nil

      output_data.each do |output_file|
        case output_file["type"]
        when "MP4"
          content_mp4_paths[output_file["profiles"].first] = output_file["path"]
        when "HLS"
          manifest_hls = select_output_file(manifest_hls, output_file)
        when "DASH"
          manifest_dash = select_output_file(manifest_dash, output_file)
        when "THUMBNAILS"
          update_thumbnail_path(output_file)
        end
      end

      updates = { "content_mp4_paths" => content_mp4_paths }
      updates["manifest_hls_path"] = manifest_hls["path"] if manifest_hls
      updates["manifest_dash_path"] = manifest_dash["path"] if manifest_dash
      media_file.remote_services_data.merge!(updates)
    end

    def select_output_file(current, incoming)
      current.present? && current["profiles"].count > incoming["profiles"].count ? current : incoming
    end

    def update_thumbnail_path(output_file)
      case output_file["profiles"]
      when ["cover"]
        media_file.remote_services_data["cover_path"] = output_file["path"]
      when ["thumb"]
        media_file.remote_services_data["thumbnails_path"] = output_file["path"]
      end
    end

    def broadcast_encoding_progress
      return if message_bus_user_ids.blank?

      phase = media_file.remote_services_data["current_phase"]
      retry_count = media_file.remote_services_data["retry_count"].to_i

      failed_label = if media_file.processing_failed?
        if retry_count < 2 && media_file.remote_services_data["retry_scheduled_at"].present?
          I18n.t("folio.console.files.show.encoding_info_component.phase_failed_retrying")
        else
          I18n.t("folio.console.files.show.encoding_info_component.phase_failed")
        end
      end

      phase_label = if phase.present?
        encoding_phase = media_file.remote_services_data["current_encoding_phase"]
        if multi_phase? && encoding_phase.present?
          phase_name = media_file.encoder_phase_name(encoding_phase)
          if phase_name
            I18n.t("folio.console.files.show.encoding_info_component.phase_#{phase}_named",
                   name: phase_name,
                   default: I18n.t("folio.console.files.show.encoding_info_component.phase_#{phase}", default: phase.humanize))
          else
            I18n.t("folio.console.files.show.encoding_info_component.phase_#{phase}_multi",
                   phase: encoding_phase,
                   total: expected_phases,
                   default: I18n.t("folio.console.files.show.encoding_info_component.phase_#{phase}", default: phase.humanize))
          end
        else
          I18n.t("folio.console.files.show.encoding_info_component.phase_#{phase}", default: phase.humanize)
        end
      end

      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                         {
                           type: "Folio::CraMediaCloud::CheckProgressJob/encoding_progress",
                           data: {
                             id: media_file.id,
                             aasm_state: media_file.aasm_state,
                             aasm_state_human: serialized_file(media_file).dig(:data, :attributes, :aasm_state_human),
                             progress_percentage: media_file.remote_services_data["progress_percentage"],
                             current_phase: phase,
                             current_phase_label: phase_label,
                             failed_label: failed_label,
                             cra_status: media_file.remote_services_data["cra_status"],
                           },
                         }.to_json,
                         user_ids: message_bus_user_ids
    end

    def check_again_later
      Folio::CraMediaCloud::CheckProgressJob.set(wait: 15.seconds).perform_later(
        media_file,
        encoding_generation: @encoding_generation || media_file.encoding_generation
      )
    end

    def processing_timed_out?
      started_at = media_file.remote_services_data["processing_step_started_at"]
      return false if started_at.blank?

      Time.parse(started_at.to_s) < MAX_PROCESSING_DURATION.ago
    end

    def api
      @api ||= Folio::CraMediaCloud::Api.new
    end
end

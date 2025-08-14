# frozen_string_literal: true

class Folio::CraMediaCloud::MonitorProcessingJob < Folio::ApplicationJob
  queue_as :default

  def perform
    # Prevent multiple instances from running simultaneously
    return if another_monitor_job_running?

    begin
      # Handle videos with orphaned or inconsistent states first
      handle_orphaned_videos

      # Handle videos needing initial upload
      handle_videos_needing_upload

      # Handle videos with failed uploads that need retry
      handle_failed_uploads_needing_retry

      # Handle videos that are already processing and need progress checking
      handle_videos_needing_progress_check
    ensure
      # Always release the lock when done
      release_monitor_job_lock
    end
  end

  private
    def find_processing_videos
      Folio::File::Video
        .where(aasm_state: :processing)
        .where("remote_services_data ->> 'service' = ?", "cra_media_cloud")
        .where("remote_services_data ->> 'processing_state' IN (?)", ["full_media_processing", "upload_completed"])
    end

    def find_videos_needing_upload
      # Find videos that need initial upload (no remote references)
      Folio::File::Video
        .where(aasm_state: :processing)
        .where(
          "(remote_services_data ->> 'service' IS NULL OR remote_services_data ->> 'service' = ?) AND " \
          "(remote_services_data ->> 'remote_id' IS NULL) AND " \
          "(remote_services_data ->> 'reference_id' IS NULL)",
          "cra_media_cloud"
        )
    end

    def find_failed_uploads_needing_retry
      # Find videos with failed uploads that should be retried after 5 minutes
      Folio::File::Video
        .where(aasm_state: :processing)
        .where("remote_services_data ->> 'service' = ?", "cra_media_cloud")
        .where("remote_services_data ->> 'processing_state' = ?", "upload_failed")
        .where("(remote_services_data ->> 'processing_step_started_at')::timestamp < ?", 5.minutes.ago)
    end

    def handle_videos_needing_upload
      videos_needing_upload = find_videos_needing_upload

      return if videos_needing_upload.empty?

      Rails.logger.info("MonitorProcessingJob: Found #{videos_needing_upload.count} videos needing upload")

      # Find videos that already have scheduled CreateMediaJob to avoid duplicates
      scheduled_create_jobs = find_scheduled_create_media_job_ids

      videos_needing_upload.each do |video|
        Rails.logger.info("MonitorProcessingJob: Checking video ##{video.id} for upload scheduling")

        if scheduled_create_jobs.include?(video.id)
          Rails.logger.info("MonitorProcessingJob: Video ##{video.id} already has a scheduled CreateMediaJob, skipping")
          next
        end

        # Check if video is stuck in creating state
        rs_data = video.remote_services_data || {}
        Rails.logger.info("MonitorProcessingJob: Video ##{video.id} remote_services_data: #{rs_data}")

        if rs_data["processing_state"] == "creating_media_job"
          started_at = rs_data["processing_step_started_at"]
          Rails.logger.info("MonitorProcessingJob: Video ##{video.id} is in creating_media_job state, started_at: #{started_at}")

          # Check if upload is genuinely stuck vs. just taking a long time
          if started_at && !upload_is_stuck?(video, Time.parse(started_at))
            Rails.logger.info("MonitorProcessingJob: Video ##{video.id} upload appears to be progressing, not retrying yet")
            next
          end

          # Check if there's actually a running CreateMediaJob for this video
          running_create_jobs = find_running_create_media_job_ids
          if running_create_jobs.include?(video.id)
            Rails.logger.info("MonitorProcessingJob: Video ##{video.id} has a running CreateMediaJob, skipping")
            next
          else
            Rails.logger.warn("MonitorProcessingJob: Video ##{video.id} is stuck in creating_media_job state, proceeding with retry")
          end
        end

        Rails.logger.info("MonitorProcessingJob: Scheduling CreateMediaJob for video ##{video.id}")
        Folio::CraMediaCloud::CreateMediaJob.perform_later(video)
      end
    end

    def handle_failed_uploads_needing_retry
      failed_uploads = find_failed_uploads_needing_retry

      return if failed_uploads.empty?

      Rails.logger.info("MonitorProcessingJob: Found #{failed_uploads.count} failed uploads to retry")

      # Find videos that already have scheduled CreateMediaJob to avoid duplicates
      scheduled_create_jobs = find_scheduled_create_media_job_ids

      failed_uploads.each do |video|
        if scheduled_create_jobs.include?(video.id)
          Rails.logger.info("MonitorProcessingJob: Failed video ##{video.id} already has a scheduled CreateMediaJob, skipping")
          next
        end

        Rails.logger.info("MonitorProcessingJob: Retrying failed upload for video ##{video.id}")
        Folio::CraMediaCloud::CreateMediaJob.perform_later(video)
      end
    end

    def handle_videos_needing_progress_check
      processing_videos = find_processing_videos

      return if processing_videos.empty?

      Rails.logger.info("MonitorProcessingJob: Found #{processing_videos.count} videos to monitor")

      # Find videos that already have scheduled CheckProgressJob to avoid duplicates
      scheduled_check_jobs = find_scheduled_check_progress_job_ids

      processing_videos.each do |video|
        # Check for timeout first - this will mark videos as failed if they've been processing too long
        if processing_too_long?(video)
          Rails.logger.warn("MonitorProcessingJob: Video ##{video.id} processing too long")
          # If video was marked as failed, skip further processing
          next if video.reload.aasm_state == "processing_failed"
        end

        if scheduled_check_jobs.include?(video.id)
          Rails.logger.debug("MonitorProcessingJob: Video ##{video.id} already has a scheduled CheckProgressJob, skipping")
          next
        end

        # Check if video is still in creating_media_job state
        rs_data = video.remote_services_data || {}
        if rs_data["processing_state"] == "creating_media_job"
          Rails.logger.debug("MonitorProcessingJob: Video ##{video.id} is still in creating_media_job state, skipping CheckProgressJob")
          next
        end

        Rails.logger.debug("MonitorProcessingJob: Scheduling CheckProgressJob for video ##{video.id}")
        Folio::CraMediaCloud::CheckProgressJob.perform_later(video)
      end
    end

    def handle_orphaned_videos
      # Find videos that might be in inconsistent states
      orphaned_videos = find_orphaned_videos

      return if orphaned_videos.empty?

      Rails.logger.info("MonitorProcessingJob: Found #{orphaned_videos.count} potentially orphaned videos")

      orphaned_videos.each do |video|
        Rails.logger.info("MonitorProcessingJob: Checking orphaned video ##{video.id}")

        begin
          # Try to reconcile the video state with remote jobs
          reconcile_video_state(video)
        rescue => e
          Rails.logger.error("MonitorProcessingJob: Error reconciling video ##{video.id}: #{e.message}")
        end
      end
    end

    def find_orphaned_videos
      # Find videos that are processing but might have lost track of their remote jobs
      Folio::File::Video
        .where(aasm_state: :processing)
        .where("remote_services_data ->> 'service' = ?", "cra_media_cloud")
        .where(
          # Videos with reference_id but no remote_id, or videos that have been
          # in creating_media_job state for a very long time
          "(remote_services_data ->> 'reference_id' IS NOT NULL AND remote_services_data ->> 'remote_id' IS NULL) OR " \
          "(remote_services_data ->> 'processing_state' = 'creating_media_job' AND " \
          "(remote_services_data ->> 'processing_step_started_at')::timestamp < ?)",
          3.hours.ago
        )
    end

    def reconcile_video_state(video)
      rs_data = video.remote_services_data || {}
      reference_id = rs_data["reference_id"]

      return unless reference_id

      Rails.logger.info("MonitorProcessingJob: Reconciling video ##{video.id} with reference_id: #{reference_id}")

      begin
        api = Folio::CraMediaCloud::Api.new
        jobs = api.get_jobs(ref_id: reference_id)

        if jobs.empty?
          Rails.logger.warn("MonitorProcessingJob: No remote jobs found for video ##{video.id} reference_id: #{reference_id}")
          # Video has reference_id but no remote jobs - needs re-upload
          rs_data.delete("reference_id")
          rs_data.delete("remote_id")
          rs_data.delete("processing_state")
          video.update_column(:remote_services_data, rs_data)
          Rails.logger.info("MonitorProcessingJob: Cleared state for video ##{video.id} - will be re-uploaded")
          return
        end

        # Get the most recent job
        latest_job = jobs.max_by { |j| Time.parse(j["lastModified"]) }
        current_remote_id = rs_data["remote_id"]

        Rails.logger.info("MonitorProcessingJob: Latest job for video ##{video.id}: #{latest_job['id']} (status: #{latest_job['status']})")

        case latest_job["status"]
        when "DONE"
          if current_remote_id != latest_job["id"]
            Rails.logger.info("MonitorProcessingJob: Updating video ##{video.id} to point to successful job #{latest_job['id']}")
            rs_data["remote_id"] = latest_job["id"]
            rs_data["processing_state"] = "full_media_processing"
            video.update_column(:remote_services_data, rs_data)

            # Schedule progress check to update final state
            Folio::CraMediaCloud::CheckProgressJob.perform_later(video)
          end
        when "PROCESSING", "CREATED"
          if current_remote_id != latest_job["id"]
            Rails.logger.info("MonitorProcessingJob: Updating video ##{video.id} to point to processing job #{latest_job['id']}")
            rs_data["remote_id"] = latest_job["id"]
            rs_data["processing_state"] = "full_media_processing"
            video.update_column(:remote_services_data, rs_data)
          end

          # Schedule progress check
          Folio::CraMediaCloud::CheckProgressJob.perform_later(video)
        when "FAILED", "ERROR"
          Rails.logger.warn("MonitorProcessingJob: Latest job for video ##{video.id} failed, marking for retry")
          rs_data.merge!({
            "processing_state" => "upload_failed",
            "error_message" => "Remote job failed: #{latest_job['status']}",
            "processing_step_started_at" => Time.current.iso8601
          })
          video.update_column(:remote_services_data, rs_data)
        end

      rescue => e
        Rails.logger.error("MonitorProcessingJob: API error while reconciling video ##{video.id}: #{e.message}")
        # Don't change video state if API call fails
      end
    end

    def find_scheduled_create_media_job_ids
      extract_video_ids_from_jobs("Folio::CraMediaCloud::CreateMediaJob")
    end

    def find_running_create_media_job_ids
      extract_video_ids_from_running_jobs("Folio::CraMediaCloud::CreateMediaJob")
    end

    def find_scheduled_check_progress_job_ids
      extract_video_ids_from_jobs("Folio::CraMediaCloud::CheckProgressJob")
    end

    def extract_video_ids_from_jobs(job_class)
      scheduled_ids = []

      # Check Sidekiq scheduled jobs
      Sidekiq::ScheduledSet.new.each do |job|
        job_data = job.args.first
        next unless job_data.is_a?(Hash) && job_data["job_class"] == job_class

        video_id = extract_video_id_from_job_data(job_data)
        scheduled_ids << video_id if video_id
      end

      # Check Sidekiq retry set (failed jobs that will retry)
      Sidekiq::RetrySet.new.each do |job|
        job_data = job.args.first
        next unless job_data.is_a?(Hash) && job_data["job_class"] == job_class

        video_id = extract_video_id_from_job_data(job_data)
        scheduled_ids << video_id if video_id
      end

      # Check Sidekiq working set (currently running jobs)
      Sidekiq::Workers.new.each do |process_id, thread_id, work|
        if work["payload"]["job_class"] == job_class
          global_id = work["payload"]["arguments"].first["_aj_globalid"]
          if global_id.include?("Folio::File::Video")
            scheduled_ids << global_id.split("/").last.to_i
          end
        end
      end

      scheduled_ids.compact.uniq
    end

    def extract_video_ids_from_running_jobs(job_class)
      running_ids = []

      # Check only Sidekiq working set (currently running jobs)
      Sidekiq::Workers.new.each do |process_id, thread_id, work|
        if work["payload"]["job_class"] == job_class
          global_id = work["payload"]["arguments"].first["_aj_globalid"]
          if global_id.include?("Folio::File::Video")
            running_ids << global_id.split("/").last.to_i
          end
        end
      end

      running_ids.compact.uniq
    rescue => e
      Rails.logger.error("MonitorProcessingJob: Error checking running jobs: #{e.message}")
      []
    end

    def extract_video_id_from_job_data(job_data)
      return nil unless job_data["arguments"]&.first&.is_a?(Hash)

      global_id = job_data["arguments"].first["_aj_globalid"]
      if global_id&.include?("Folio::File::Video")
        global_id.split("/").last.to_i
      end
    rescue => e
      Rails.logger.debug("MonitorProcessingJob: Error extracting video ID from job: #{e.message}")
      nil
    end

    def processing_too_long?(video)
      # Consider a video stuck if it's been processing for more than 2 hours
      started_at = video.remote_services_data["processing_step_started_at"]
      return false unless started_at

      elapsed_hours = (Time.current - Time.parse(started_at)) / 1.hour

      if elapsed_hours > 2
        Rails.logger.warn("MonitorProcessingJob: Video ##{video.id} has been processing for #{elapsed_hours.round(1)} hours")

        # Mark as failed after very long processing (6+ hours)
        if elapsed_hours > 6
          Rails.logger.error("MonitorProcessingJob: Marking video ##{video.id} as failed after #{elapsed_hours.round(1)} hours")
          video.processing_failed!
          return true
        end
      end

      elapsed_hours > 2
    rescue => e
      Rails.logger.error("MonitorProcessingJob: Error checking processing time for video ##{video.id}: #{e.message}")
      false
    end

    def upload_is_stuck?(video, upload_started_at)
      rs_data = video.remote_services_data || {}
      rs_data["upload_progress"]

      # Calculate appropriate timeout based on file size
      file_size = video.file_size || 0
      base_timeout = 5.minutes # Base timeout for small files

      # Add extra time for large files (1 minute per 100MB)
      size_based_timeout = (file_size / 100.megabytes) * 1.minute
      total_timeout = base_timeout + size_based_timeout

      # Cap the timeout at 30 minutes for very large files
      total_timeout = [total_timeout, 30.minutes].min

      elapsed_time = Time.current - upload_started_at

      Rails.logger.debug("MonitorProcessingJob: Video ##{video.id} upload timeout check: elapsed #{elapsed_time.round(0)}s, timeout #{total_timeout.round(0)}s")


      # Fallback to time-based check if no progress data
      if elapsed_time > total_timeout
        Rails.logger.warn("MonitorProcessingJob: Video ##{video.id} upload timeout: #{elapsed_time.round(0)}s > #{total_timeout.round(0)}s")
        return true
      end

      false
    end

    def redis_client
      # Modern Redis connection approach replacing deprecated Redis.current
      @redis_client ||= Redis.new(
        url: redis_url,
        timeout: redis_timeout,
        reconnect_attempts: redis_reconnect_attempts,
        reconnect_delay: redis_reconnect_delay,
        reconnect_delay_max: redis_reconnect_delay_max
      )
    end

    def redis_url
      ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
    end

    def redis_timeout
      ENV.fetch("REDIS_TIMEOUT", 1).to_i
    end

    def redis_reconnect_attempts
      ENV.fetch("REDIS_RECONNECT_ATTEMPTS", 3).to_i
    end

    def redis_reconnect_delay
      ENV.fetch("REDIS_RECONNECT_DELAY", 0.5).to_f
    end

    def redis_reconnect_delay_max
      ENV.fetch("REDIS_RECONNECT_DELAY_MAX", 5).to_f
    end

    def another_monitor_job_running?
      # Use Redis-based locking to prevent multiple instances
      redis_key = "folio:cra_monitor:job_lock"

      # Try to acquire lock with 5-minute expiration
      lock_acquired = redis_client.set(redis_key, Process.pid, nx: true, ex: 300)

      if lock_acquired
        Rails.logger.debug("MonitorProcessingJob: Lock acquired")
        false
      else
        Rails.logger.info("MonitorProcessingJob: Another instance is already running, skipping")
        true
      end
    rescue => e
      Rails.logger.error("MonitorProcessingJob: Error checking for running instances: #{e.message}")
      false
    end

    def release_monitor_job_lock
      redis_key = "folio:cra_monitor:job_lock"
      # Only release if we own the lock (safety check)
      script = <<~LUA
        if redis.call("get", KEYS[1]) == ARGV[1] then
          return redis.call("del", KEYS[1])
        else
          return 0
        end
      LUA

      redis_client.eval(script, keys: [redis_key], argv: [Process.pid.to_s])
    rescue => e
      Rails.logger.debug("MonitorProcessingJob: Error releasing lock: #{e.message}")
    end
end

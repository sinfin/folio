# frozen_string_literal: true

class Folio::CloudflareStream::MonitorProcessingJob < Folio::ApplicationJob
  queue_as :default

  unique :until_and_while_executing

  def perform
    scheduled_count = 0
    skipped_scheduled_count = 0
    skipped_fresh_count = 0

    Rails.logger.info("[CloudflareStream::MonitorProcessingJob] Started stale_after=#{stale_after.inspect}")

    scheduled_ids = scheduled_check_progress_job_ids

    candidate_videos.find_each do |video|
      unless stale?(video)
        skipped_fresh_count += 1
        next
      end

      if scheduled_ids.include?(video.id)
        skipped_scheduled_count += 1
        Rails.logger.info("[CloudflareStream::MonitorProcessingJob] Video ##{video.id} already has scheduled CheckProgressJob")
        next
      end

      Rails.logger.info("[CloudflareStream::MonitorProcessingJob] Scheduling CheckProgressJob for video ##{video.id} uid=#{video.remote_services_data['uid']}")
      Folio::CloudflareStream::CheckProgressJob.perform_later(video, encoding_generation: encoding_generation_for(video))
      scheduled_count += 1
    rescue => e
      Rails.logger.error("[CloudflareStream::MonitorProcessingJob] Failed to inspect video ##{video.id}: #{e.class}: #{e.message}")
    end

    Rails.logger.info(
      "[CloudflareStream::MonitorProcessingJob] Finished scheduled=#{scheduled_count} " \
      "skipped_scheduled=#{skipped_scheduled_count} skipped_fresh=#{skipped_fresh_count}"
    )
  end

  private
    def candidate_videos
      Folio::File::Video
        .where(aasm_state: :processing)
        .where("remote_services_data ->> 'service' = ?", "cloudflare_stream")
        .where("remote_services_data ->> 'processing_state' = ?", "processing")
        .where("remote_services_data ->> 'uid' IS NOT NULL")
        .where("remote_services_data ->> 'uid' != ''")
    end

    def stale?(video)
      last_checked_at = parse_timestamp(video.remote_services_data["last_progress_check_at"]) || video.updated_at
      last_checked_at < stale_after.ago
    end

    def parse_timestamp(value)
      return if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      Rails.logger.warn("[CloudflareStream::MonitorProcessingJob] Ignoring invalid last_progress_check_at=#{value.inspect}")
      nil
    end

    def encoding_generation_for(video)
      video.respond_to?(:encoding_generation) ? video.encoding_generation : video.remote_services_data["encoding_generation"]
    end

    def stale_after
      Rails.application.config.folio_cloudflare_stream_monitor_stale_after
    end

    def scheduled_check_progress_job_ids
      extract_video_ids_from_jobs("Folio::CloudflareStream::CheckProgressJob")
    rescue => e
      Rails.logger.warn("[CloudflareStream::MonitorProcessingJob] Could not inspect scheduled Sidekiq jobs: #{e.class}: #{e.message}")
      []
    end

    def extract_video_ids_from_jobs(job_class)
      (video_ids_from_scheduled_jobs(job_class) + video_ids_from_retry_jobs(job_class) + video_ids_from_running_jobs(job_class)).compact.uniq
    end

    def video_ids_from_scheduled_jobs(job_class)
      Sidekiq::ScheduledSet.new.filter_map { |job| video_id_from_sidekiq_job(job, job_class) }
    end

    def video_ids_from_retry_jobs(job_class)
      Sidekiq::RetrySet.new.filter_map { |job| video_id_from_sidekiq_job(job, job_class) }
    end

    def video_ids_from_running_jobs(job_class)
      Sidekiq::Workers.new.filter_map do |_process_id, _thread_id, work|
        next unless work.dig("payload", "job_class") == job_class

        video_id_from_active_job_arguments(work.dig("payload", "arguments"))
      end
    end

    def video_id_from_sidekiq_job(job, job_class)
      job_data = job.args.first
      return unless job_data.is_a?(Hash) && job_data["job_class"] == job_class

      video_id_from_active_job_arguments(job_data["arguments"])
    rescue => e
      Rails.logger.debug("[CloudflareStream::MonitorProcessingJob] Could not parse scheduled job #{job.jid}: #{e.class}: #{e.message}")
      nil
    end

    def video_id_from_active_job_arguments(arguments)
      global_id = arguments&.first&.dig("_aj_globalid")
      return unless global_id&.include?("Folio::File::Video")

      global_id.split("/").last.to_i
    end
end

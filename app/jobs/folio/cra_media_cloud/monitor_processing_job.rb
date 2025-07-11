# frozen_string_literal: true

class Folio::CraMediaCloud::MonitorProcessingJob < Folio::ApplicationJob
  queue_as :default

  def perform
    # Find all video files in processing state that use CRA Media Cloud
    processing_videos = find_processing_videos

    return if processing_videos.empty?

    scheduled_video_ids = find_scheduled_video_ids

    processing_videos.each do |video|
      # Skip if this video already has a CheckProgressJob scheduled
      next if scheduled_video_ids.include?(video.id)
      
      # Skip if video has been processing for too long (avoid infinite loops)
      next if processing_too_long?(video)
      
      # Schedule a CheckProgressJob for this video
      Rails.logger.info("MonitorProcessingJob: Scheduling progress check for video ##{video.id}")
      Folio::CraMediaCloud::CheckProgressJob.perform_later(video)
    end

    Rails.logger.info("MonitorProcessingJob: Checked #{processing_videos.count} videos, scheduled #{processing_videos.count - scheduled_video_ids.count} progress checks")
  end

  private

    def find_processing_videos
      Folio::File::Video
        .where(aasm_state: :processing)
        .where("remote_services_data ->> 'service' = ?", "cra_media_cloud")
        .where.not("remote_services_data ->> 'processing_state' = ?", "full_media_processed")
    end

    def find_scheduled_video_ids
      # Get all pending CheckProgressJob instances and extract video IDs
      scheduled_ids = []

      # Check Sidekiq scheduled jobs
      Sidekiq::ScheduledSet.new.each do |job|
        args = job.args.first
        if args.is_a?(Hash) && args["job_class"] == "Folio::CraMediaCloud::CheckProgressJob"
          global_id = args["arguments"].first["_aj_globalid"]
          if global_id.include?("Folio::File::Video")
            id = global_id.split("/").last.to_i
            scheduled_ids << id
          end
        end
      end

      # Check Sidekiq retry set (failed jobs that will retry)
      Sidekiq::RetrySet.new.each do |job|
        args = job.args.first
        if args.is_a?(Hash) && args["job_class"] == "Folio::CraMediaCloud::CheckProgressJob"
          global_id = args["arguments"].first["_aj_globalid"]
          if global_id.include?("Folio::File::Video")
            id = global_id.split("/").last.to_i
            scheduled_ids << id
          end
        end
      end

      scheduled_ids.uniq
    end

    def processing_too_long?(video)
      # Consider a video stuck if it's been processing for more than 2 hours
      started_at = video.remote_services_data["processing_step_started_at"]
      return false unless started_at

      elapsed_hours = (Time.current - Time.parse(started_at)) / 1.hour
      
      if elapsed_hours > 2
        Rails.logger.warn("MonitorProcessingJob: Video ##{video.id} has been processing for #{elapsed_hours.round(1)} hours")
        
        # Optionally mark as failed after very long processing
        if elapsed_hours > 6
          Rails.logger.error("MonitorProcessingJob: Marking video ##{video.id} as failed after #{elapsed_hours.round(1)} hours")
          video.skip_subtitles_validation = true
          video.processing_failed!
          return true
        end
      end

      elapsed_hours > 2
    rescue => e
      Rails.logger.error("MonitorProcessingJob: Error checking processing time for video ##{video.id}: #{e.message}")
      false
    end
end 
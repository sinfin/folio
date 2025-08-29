# frozen_string_literal: true

require "test_helper"

class Folio::CraMediaCloud::MonitorProcessingJobTest < ActiveJob::TestCase
  test "schedules progress checks for processing videos" do
    # Create a video file in processing state
    video = create(:folio_file_video)
    video.update!(
      aasm_state: :processing,
      remote_services_data: {
        "service" => "cra_media_cloud",
        "processing_state" => "upload_completed",
        "processing_step_started_at" => 10.minutes.ago.iso8601
      }
    )

    # Verify CheckProgressJob is scheduled
    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
      Folio::CraMediaCloud::MonitorProcessingJob.perform_now
    end
  end

  test "skips videos that are already fully processed" do
    # Create a video file that's already processed
    video = create(:folio_file_video)
    video.update!(
      aasm_state: :processing,
      remote_services_data: {
        "service" => "cra_media_cloud",
        "processing_state" => "full_media_processed"
      }
    )

    # No jobs should be scheduled
    assert_enqueued_jobs 0, only: Folio::CraMediaCloud::CheckProgressJob do
      Folio::CraMediaCloud::MonitorProcessingJob.perform_now
    end
  end

  test "returns early when no processing videos exist" do
    # No processing videos exist
    assert_enqueued_jobs 0 do
      Folio::CraMediaCloud::MonitorProcessingJob.perform_now
    end
  end

  test "marks videos as failed after processing too long" do
    # Create a video that's been processing for over 6 hours
    video = create(:folio_file_video)
    video.update!(
      aasm_state: :processing,
      remote_services_data: {
        "service" => "cra_media_cloud",
        "processing_state" => "upload_completed",
        "processing_step_started_at" => 7.hours.ago.iso8601
      }
    )

    Folio::CraMediaCloud::MonitorProcessingJob.perform_now

    video.reload
    assert_equal "processing_failed", video.aasm_state
  end
end

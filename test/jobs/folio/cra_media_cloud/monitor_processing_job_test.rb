# frozen_string_literal: true

require "test_helper"

class Folio::CraMediaCloud::MonitorProcessingJobTest < ActiveJob::TestCase
  def with_unlocked_monitor_job(&block)
    fake_redis = Class.new do
      def set(*, **)
        "OK" # emulate successful NX lock acquisition
      end
      def eval(*); end # no-op for lock release
    end.new

    # Wrap perform via instance stub
    job = Folio::CraMediaCloud::MonitorProcessingJob.new
    job.stub(:redis_client, fake_redis, &block)
  end

  test "schedules progress checks for processing videos" do
    video = create(:folio_file_video)
    video.update!(
      aasm_state: :processing,
      remote_services_data: {
        "service" => "cra_media_cloud",
        "processing_state" => "upload_completed",
        "processing_step_started_at" => 10.minutes.ago.iso8601
      }
    )

    with_unlocked_monitor_job do
      assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
        Folio::CraMediaCloud::MonitorProcessingJob.perform_now
      end
    end
  end

  test "skips videos that are already fully processed" do
    video = create(:folio_file_video)
    video.update!(
      aasm_state: :processing,
      remote_services_data: {
        "service" => "cra_media_cloud",
        "processing_state" => "full_media_processed"
      }
    )

    with_unlocked_monitor_job do
      assert_enqueued_jobs 0, only: Folio::CraMediaCloud::CheckProgressJob do
        Folio::CraMediaCloud::MonitorProcessingJob.perform_now
      end
    end
  end

  test "returns early when no processing videos exist" do
    with_unlocked_monitor_job do
      assert_enqueued_jobs 0 do
        Folio::CraMediaCloud::MonitorProcessingJob.perform_now
      end
    end
  end

  test "marks videos as failed after processing too long" do
    video = create(:folio_file_video)
    video.update!(
      aasm_state: :processing,
      remote_services_data: {
        "service" => "cra_media_cloud",
        "processing_state" => "upload_completed",
        "processing_step_started_at" => 7.hours.ago.iso8601
      }
    )

    with_unlocked_monitor_job do
      Folio::CraMediaCloud::MonitorProcessingJob.perform_now
    end

    video.reload
    assert_equal "processing_failed", video.aasm_state
  end
end

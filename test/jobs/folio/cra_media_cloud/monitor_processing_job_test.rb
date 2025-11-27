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

  test "upload_is_stuck? returns false for small file within timeout" do
    video = create(:folio_file_video, file_size: 10.megabytes)
    upload_started_at = 2.minutes.ago

    job = Folio::CraMediaCloud::MonitorProcessingJob.new
    result = job.send(:upload_is_stuck?, video, upload_started_at)

    assert_equal false, result
  end

  test "upload_is_stuck? returns true for small file exceeding timeout" do
    video = create(:folio_file_video, file_size: 10.megabytes)
    upload_started_at = 6.minutes.ago

    job = Folio::CraMediaCloud::MonitorProcessingJob.new
    result = job.send(:upload_is_stuck?, video, upload_started_at)

    assert_equal true, result
  end

  test "upload_is_stuck? calculates timeout based on file size" do
    # 200MB file should get: 5 minutes base + (200MB / 100MB) * 1 minute = 7 minutes total
    video = create(:folio_file_video, file_size: 200.megabytes)
    
    # Within timeout (6 minutes < 7 minutes)
    upload_started_at = 6.minutes.ago
    job = Folio::CraMediaCloud::MonitorProcessingJob.new
    result = job.send(:upload_is_stuck?, video, upload_started_at)
    assert_equal false, result

    # Exceeding timeout (8 minutes > 7 minutes)
    upload_started_at = 8.minutes.ago
    result = job.send(:upload_is_stuck?, video, upload_started_at)
    assert_equal true, result
  end

  test "upload_is_stuck? caps timeout at 30 minutes for very large files" do
    # 5GB file would calculate to: 5 minutes + (5000MB / 100MB) * 1 minute = 55 minutes
    # But should be capped at 30 minutes
    video = create(:folio_file_video, file_size: 5.gigabytes)
    
    # Within capped timeout (25 minutes < 30 minutes)
    upload_started_at = 25.minutes.ago
    job = Folio::CraMediaCloud::MonitorProcessingJob.new
    result = job.send(:upload_is_stuck?, video, upload_started_at)
    assert_equal false, result

    # Exceeding capped timeout (35 minutes > 30 minutes)
    upload_started_at = 35.minutes.ago
    result = job.send(:upload_is_stuck?, video, upload_started_at)
    assert_equal true, result
  end

  test "upload_is_stuck? handles nil file_size" do
    video = create(:folio_file_video, file_size: nil)
    upload_started_at = 2.minutes.ago

    job = Folio::CraMediaCloud::MonitorProcessingJob.new
    result = job.send(:upload_is_stuck?, video, upload_started_at)

    # Should use base timeout of 5 minutes
    assert_equal false, result
  end

  test "upload_is_stuck? handles zero file_size" do
    video = create(:folio_file_video, file_size: 0)
    upload_started_at = 2.minutes.ago

    job = Folio::CraMediaCloud::MonitorProcessingJob.new
    result = job.send(:upload_is_stuck?, video, upload_started_at)

    # Should use base timeout of 5 minutes
    assert_equal false, result
  end
end

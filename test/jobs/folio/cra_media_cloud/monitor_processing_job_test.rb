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

  test "rescues failed video awaiting retry when retry job is lost" do
    video = create(:folio_file_video)
    video.update!(
      aasm_state: :processing_failed,
      remote_services_data: {
        "service" => "cra_media_cloud",
        "retry_count" => 1,
        "retry_scheduled_at" => 10.minutes.ago.iso8601,
      }
    )

    with_unlocked_monitor_job do
      assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CreateMediaJob do
        Folio::CraMediaCloud::MonitorProcessingJob.perform_now
      end
    end
  end

  test "does not rescue finally failed video (retry_count >= 2)" do
    video = create(:folio_file_video)
    video.update!(
      aasm_state: :processing_failed,
      remote_services_data: {
        "service" => "cra_media_cloud",
        "retry_count" => 2,
      }
    )

    with_unlocked_monitor_job do
      assert_no_enqueued_jobs only: Folio::CraMediaCloud::CreateMediaJob do
        Folio::CraMediaCloud::MonitorProcessingJob.perform_now
      end
    end
  end

  test "triggers process! for stuck unprocessed video with file_uid" do
    video = create(:folio_file_video)
    video.update_columns(
      aasm_state: "unprocessed",
      file_uid: "2026/03/09/13/20/26/test-uuid/test.mp4",
      created_at: 10.minutes.ago
    )

    with_unlocked_monitor_job do
      Folio::CraMediaCloud::MonitorProcessingJob.perform_now
    end

    video.reload
    assert_not_equal "unprocessed", video.aasm_state, "Video should no longer be unprocessed after safety net"
  end

  test "does not trigger process! for recently created unprocessed video" do
    video = create(:folio_file_video)
    video.update_columns(
      aasm_state: "unprocessed",
      file_uid: "2026/03/09/13/20/26/test-uuid/test.mp4",
      created_at: 2.minutes.ago
    )

    with_unlocked_monitor_job do
      Folio::CraMediaCloud::MonitorProcessingJob.perform_now
    end

    video.reload
    assert_equal "unprocessed", video.aasm_state
  end

  test "does not trigger process! for unprocessed video without file_uid" do
    video = create(:folio_file_video)
    video.update_columns(
      aasm_state: "unprocessed",
      file_uid: nil,
      created_at: 10.minutes.ago
    )

    with_unlocked_monitor_job do
      Folio::CraMediaCloud::MonitorProcessingJob.perform_now
    end

    video.reload
    assert_equal "unprocessed", video.aasm_state
  end

  test "rescues video stuck in enqueued state for over 10 minutes" do
    video = create(:folio_file_video)
    video.update!(
      aasm_state: :processing,
      remote_services_data: {
        "service" => "cra_media_cloud",
        "processing_state" => "enqueued",
        "processing_step_started_at" => 15.minutes.ago.iso8601
      }
    )

    with_unlocked_monitor_job do
      assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CreateMediaJob do
        Folio::CraMediaCloud::MonitorProcessingJob.perform_now
      end
    end
  end

  test "does not rescue freshly enqueued video" do
    video = create(:folio_file_video)
    video.update!(
      aasm_state: :processing,
      remote_services_data: {
        "service" => "cra_media_cloud",
        "processing_state" => "enqueued",
        "processing_step_started_at" => 3.minutes.ago.iso8601
      }
    )

    with_unlocked_monitor_job do
      assert_no_enqueued_jobs only: Folio::CraMediaCloud::CreateMediaJob do
        Folio::CraMediaCloud::MonitorProcessingJob.perform_now
      end
    end
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

  # --- reconcile_with_remote_jobs: all-REMOVED path ---

  test "reconcile_with_remote_jobs schedules CheckProgressJob when all CRA jobs are REMOVED" do
    video = create(:folio_file_video)
    rs_data = {
      "service" => "cra_media_cloud",
      "processing_state" => "full_media_processing",
      "reference_id" => "REF123",
      "encoding_generation" => 42,
      "phase_1_completed_at" => 5.minutes.ago.iso8601,
      "phase_1_content_mp4_paths" => { "sd0" => "/video/sd0.mp4" },
    }
    video.update_column(:remote_services_data, rs_data)

    removed_jobs = [
      { "id" => "JOB1", "status" => "REMOVED", "phase" => 1, "lastModified" => 2.minutes.ago.iso8601 },
      { "id" => "JOB2", "status" => "REMOVED", "phase" => 2, "lastModified" => 1.minute.ago.iso8601 },
    ]

    job = Folio::CraMediaCloud::MonitorProcessingJob.new

    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
      job.send(:reconcile_with_remote_jobs, video, rs_data, removed_jobs)
    end

    # Should NOT update processing_state — CheckProgressJob handles finalization
    video.reload
    assert_equal "full_media_processing", video.remote_services_data["processing_state"]
  end
end

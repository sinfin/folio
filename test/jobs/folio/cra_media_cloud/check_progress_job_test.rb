# frozen_string_literal: true

require "test_helper"

class Folio::CraMediaCloud::CheckProgressJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::CraMediaCloud::FileProcessing
  end

  # --- Encoding generation tests ---

  test "skips processing when encoding_generation doesn't match (stale job)" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "encoding_generation" => 12345,
      "reference_id" => "REF123"
    ))

    assert_no_enqueued_jobs only: Folio::CraMediaCloud::CheckProgressJob do
      Folio::CraMediaCloud::CheckProgressJob.perform_now(video, encoding_generation: 11111)
    end

    video.reload
    assert_equal "full_media_processing", video.remote_services_data["processing_state"]
  end

  test "processes normally when encoding_generation matches" do
    video = create_test_video_in_processing_state
    current_generation = 12345
    video.update!(remote_services_data: video.remote_services_data.merge(
      "encoding_generation" => current_generation,
      "reference_id" => "REF123"
    ))

    api_response = { "id" => "JOB123", "status" => "PROCESSING", "progress" => 0.5,
                     "lastModified" => Time.current.iso8601 }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [api_response], [], ref_id: "REF123")

    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
      expect_method_called_on(
        object: Folio::CraMediaCloud::Api,
        method: :new,
        return_value: api_mock
      ) do
        Folio::CraMediaCloud::CheckProgressJob.perform_now(video, encoding_generation: current_generation)
      end
    end

    api_mock.verify
  end

  test "processes normally when encoding_generation is nil (backwards compatibility)" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "reference_id" => "REF123"
    ))

    api_response = { "id" => "JOB123", "status" => "PROCESSING", "progress" => 0.5,
                     "lastModified" => Time.current.iso8601 }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [api_response], [], ref_id: "REF123")

    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
      expect_method_called_on(
        object: Folio::CraMediaCloud::Api,
        method: :new,
        return_value: api_mock
      ) do
        Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
      end
    end

    api_mock.verify
  end

  # --- Multi-phase tests ---

  test "phase 1 DONE does not trigger processing_done when processing_phases is 2" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "processing_phases" => 2,
      "remote_id" => "JOB_PHASE1",
      "reference_id" => "REF123"
    ))

    phase1_job = {
      "id" => "JOB_PHASE1",
      "status" => "DONE",
      "phase" => 1,
      "processingPhases" => 2,
      "progress" => 1.0,
      "lastModified" => Time.current.iso8601,
      "output" => [
        { "type" => "MP4", "profiles" => ["sd0"], "path" => "/video/sd0.mp4" },
        { "type" => "MP4", "profiles" => ["sd1"], "path" => "/video/sd1.mp4" },
        { "type" => "MP4", "profiles" => ["sd2"], "path" => "/video/sd2.mp4" },
        { "type" => "HLS", "profiles" => ["sd0", "sd1", "sd2"], "path" => "/video/sd_master.m3u8" },
        { "type" => "DASH", "profiles" => ["sd0", "sd1", "sd2"], "path" => "/video/sd_manifest.mpd" },
        { "type" => "THUMBNAILS", "profiles" => ["cover"], "path" => "/video/cover.jpg" },
        { "type" => "THUMBNAILS", "profiles" => ["thumb"], "path" => "/video/thumb.vtt" },
      ]
    }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_job, phase1_job, ["JOB_PHASE1"])

    # Should reschedule (phase 1 done, waiting for phase 2)
    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
      expect_method_called_on(
        object: Folio::CraMediaCloud::Api,
        method: :new,
        return_value: api_mock
      ) do
        Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
      end
    end

    api_mock.verify
    video.reload

    # AASM should stay in processing (not ready)
    assert_equal "processing", video.aasm_state
    assert_equal "full_media_processing", video.remote_services_data["processing_state"]

    # Intermediate phase data should be saved
    assert_equal({ "sd0" => "/video/sd0.mp4", "sd1" => "/video/sd1.mp4", "sd2" => "/video/sd2.mp4" },
                 video.remote_services_data["phase_1_content_mp4_paths"])
    assert_equal "JOB_PHASE1", video.remote_services_data["phase_1_remote_id"]
    assert video.remote_services_data["phase_1_completed_at"].present?

    # Manifest/cover/thumbnails paths populated for immediate playability
    assert_equal "/video/sd_master.m3u8", video.remote_services_data["manifest_hls_path"]
    assert_equal "/video/sd_manifest.mpd", video.remote_services_data["manifest_dash_path"]
    assert_equal "/video/cover.jpg", video.remote_services_data["cover_path"]
    assert_equal "/video/thumb.vtt", video.remote_services_data["thumbnails_path"]
  end

  test "phase 2 DONE triggers processing_done" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "processing_phases" => 2,
      "reference_id" => "REF123",
      "phase_1_content_mp4_paths" => { "sd0" => "/video/sd0.mp4", "sd1" => "/video/sd1.mp4" },
      "phase_1_completed_at" => 1.minute.ago.iso8601,
      "phase_1_remote_id" => "JOB_PHASE1",
    ))

    full_output = [
      { "type" => "MP4", "profiles" => ["sd0"], "path" => "/video/sd0.mp4" },
      { "type" => "MP4", "profiles" => ["sd1"], "path" => "/video/sd1.mp4" },
      { "type" => "MP4", "profiles" => ["hd1"], "path" => "/video/hd1.mp4" },
      { "type" => "MP4", "profiles" => ["hd2"], "path" => "/video/hd2.mp4" },
      { "type" => "HLS", "profiles" => ["sd0", "sd1", "hd1", "hd2"], "path" => "/video/master.m3u8" },
      { "type" => "DASH", "profiles" => ["sd0", "sd1", "hd1", "hd2"], "path" => "/video/manifest.mpd" },
      { "type" => "THUMBNAILS", "profiles" => ["cover"], "path" => "/video/cover.jpg" },
      { "type" => "THUMBNAILS", "profiles" => ["thumb"], "path" => "/video/thumb.jpg" },
    ]

    phase1_job = {
      "id" => "JOB_PHASE1", "status" => "DONE", "phase" => 1,
      "processingPhases" => 2, "progress" => 1.0,
      "lastModified" => 2.minutes.ago.iso8601,
      "output" => full_output.select { |o| o["profiles"].first&.start_with?("sd") || o["type"] != "MP4" }
    }

    phase2_job = {
      "id" => "JOB_PHASE2", "status" => "DONE", "phase" => 2,
      "processingPhases" => 2, "prevPhaseJobId" => "JOB_PHASE1",
      "progress" => 1.0, "lastModified" => Time.current.iso8601,
      "output" => full_output
    }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [phase1_job, phase2_job], [], ref_id: "REF123")

    # Should NOT reschedule — processing is complete
    assert_no_enqueued_jobs only: Folio::CraMediaCloud::CheckProgressJob do
      expect_method_called_on(
        object: Folio::CraMediaCloud::Api,
        method: :new,
        return_value: api_mock
      ) do
        Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
      end
    end

    api_mock.verify
    video.reload

    assert_equal "ready", video.aasm_state
    assert_equal({ "sd0" => "/video/sd0.mp4", "sd1" => "/video/sd1.mp4",
                   "hd1" => "/video/hd1.mp4", "hd2" => "/video/hd2.mp4" },
                 video.remote_services_data["content_mp4_paths"])
    assert_equal "/video/master.m3u8", video.remote_services_data["manifest_hls_path"]
    assert_equal "/video/manifest.mpd", video.remote_services_data["manifest_dash_path"]
  end

  test "phase 2 PROCESSING continues polling with mapped progress" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "processing_phases" => 2,
      "reference_id" => "REF123",
      "phase_1_content_mp4_paths" => { "sd0" => "/video/sd0.mp4" },
    ))

    phase1_job = {
      "id" => "JOB_PHASE1", "status" => "DONE", "phase" => 1,
      "processingPhases" => 2, "progress" => 1.0,
      "lastModified" => 2.minutes.ago.iso8601,
      "output" => []
    }

    phase2_job = {
      "id" => "JOB_PHASE2", "status" => "PROCESSING", "phase" => 2,
      "processingPhases" => 2, "progress" => 0.6,
      "lastModified" => Time.current.iso8601,
    }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [phase1_job, phase2_job], [], ref_id: "REF123")

    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
      expect_method_called_on(
        object: Folio::CraMediaCloud::Api,
        method: :new,
        return_value: api_mock
      ) do
        Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
      end
    end

    api_mock.verify
    video.reload

    # Progress: 50% (phase 1 done) + 0.6 * 50% = 80%
    assert_equal 80.0, video.remote_services_data["progress_percentage"]
    assert_equal "processing", video.aasm_state
  end

  test "single-phase job backward compat — DONE triggers ready" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "reference_id" => "REF123"
    ))
    # No processing_phases key at all

    full_output = [
      { "type" => "MP4", "profiles" => ["sd0"], "path" => "/video/sd0.mp4" },
      { "type" => "MP4", "profiles" => ["hd1"], "path" => "/video/hd1.mp4" },
      { "type" => "HLS", "profiles" => ["sd0", "hd1"], "path" => "/video/master.m3u8" },
      { "type" => "DASH", "profiles" => ["sd0", "hd1"], "path" => "/video/manifest.mpd" },
      { "type" => "THUMBNAILS", "profiles" => ["cover"], "path" => "/video/cover.jpg" },
      { "type" => "THUMBNAILS", "profiles" => ["thumb"], "path" => "/video/thumb.jpg" },
    ]

    api_response = {
      "id" => "JOB123", "status" => "DONE", "progress" => 1.0,
      "lastModified" => Time.current.iso8601,
      "output" => full_output
    }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [api_response], [], ref_id: "REF123")

    assert_no_enqueued_jobs only: Folio::CraMediaCloud::CheckProgressJob do
      expect_method_called_on(
        object: Folio::CraMediaCloud::Api,
        method: :new,
        return_value: api_mock
      ) do
        Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
      end
    end

    api_mock.verify
    video.reload

    assert_equal "ready", video.aasm_state
    assert_equal({ "sd0" => "/video/sd0.mp4", "hd1" => "/video/hd1.mp4" },
                 video.remote_services_data["content_mp4_paths"])
    assert_equal "/video/master.m3u8", video.remote_services_data["manifest_hls_path"]
    assert_equal "/video/manifest.mpd", video.remote_services_data["manifest_dash_path"]
  end

  test "phase 2 FAILED triggers failure" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "processing_phases" => 2,
      "reference_id" => "REF123",
      "phase_1_content_mp4_paths" => { "sd0" => "/video/sd0.mp4" },
    ))

    phase1_job = {
      "id" => "JOB_PHASE1", "status" => "DONE", "phase" => 1,
      "processingPhases" => 2, "progress" => 1.0,
      "lastModified" => 2.minutes.ago.iso8601,
      "output" => []
    }

    phase2_job = {
      "id" => "JOB_PHASE2", "status" => "FAILED", "phase" => 2,
      "processingPhases" => 2, "progress" => 0.3,
      "lastModified" => Time.current.iso8601,
      "messages" => [{ "type" => "ERROR", "message" => "HD encoding failed" }]
    }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [phase1_job, phase2_job], [], ref_id: "REF123")

    # Should NOT reschedule — failure stops polling
    assert_no_enqueued_jobs only: Folio::CraMediaCloud::CheckProgressJob do
      expect_method_called_on(
        object: Folio::CraMediaCloud::Api,
        method: :new,
        return_value: api_mock
      ) do
        Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
      end
    end

    api_mock.verify
    video.reload

    assert_equal "upload_failed", video.remote_services_data["processing_state"]
    assert_equal "HD encoding failed", video.remote_services_data["error_message"]
  end

  # --- Existing encoding generation tests ---

  test "skips already ready video regardless of encoding_generation" do
    video = create_test_video_in_processing_state
    video.update_column(:aasm_state, "ready")
    video.update!(remote_services_data: video.remote_services_data.merge(
      "encoding_generation" => 12345,
      "reference_id" => "REF123"
    ))

    assert_no_enqueued_jobs only: Folio::CraMediaCloud::CheckProgressJob do
      Folio::CraMediaCloud::CheckProgressJob.perform_now(video, encoding_generation: 12345)
    end
  end

  # --- Progress tracking tests ---

  test "parses encoding messages for progress milestones" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "processing_state" => "full_media_processing",
      "reference_id" => "REF123"
    ))

    api_response = {
      "id" => "JOB123", "status" => "PROCESSING", "progress" => 0.5,
      "lastModified" => Time.current.iso8601,
      "outputParams" => { "duration" => 600.0 },
      "messages" => [
        { "createdDate" => "2026-02-25T10:00:00Z", "type" => "INFO", "message" => "validation started at host vodenc1" },
        { "createdDate" => "2026-02-25T10:00:05Z", "type" => "INFO", "message" => "processing started at host vodenc1" },
        { "createdDate" => "2026-02-25T10:00:06Z", "type" => "INFO", "message" => "Transcoding worker - video: going to transcode 600.0 seconds for 7 VIDEO profiles" },
        { "createdDate" => "2026-02-25T10:00:06Z", "type" => "INFO", "message" => "Transcoding worker - audio: going to transcode 600.0 seconds for 2 AUDIO profiles" },
        { "createdDate" => "2026-02-25T10:02:00Z", "type" => "INFO", "message" => "Transcoding worker - audio: finished" }
      ]
    }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [api_response], [], ref_id: "REF123")

    expect_method_called_on(
      object: Folio::CraMediaCloud::Api,
      method: :new,
      return_value: api_mock
    ) do
      Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
    end

    video.reload
    assert_equal 600.0, video.remote_services_data["video_duration"]
    assert_includes video.remote_services_data["phases_completed"], "audio"
  end

  test "DONE transition sets progress to 100 and state to ready" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "processing_state" => "full_media_processing",
      "reference_id" => "REF123"
    ))

    output = [
      { "type" => "MP4", "profiles" => ["sd1"], "path" => "/test/sd1.mp4" },
      { "type" => "MP4", "profiles" => ["hd1"], "path" => "/test/hd1.mp4" },
      { "type" => "HLS", "profiles" => ["sd1", "hd1"], "path" => "/test/master.m3u8" },
      { "type" => "DASH", "profiles" => ["sd1", "hd1"], "path" => "/test/master.mpd" },
      { "type" => "THUMBNAILS", "profiles" => ["cover"], "path" => "/test/cover.jpg" },
      { "type" => "THUMBNAILS", "profiles" => ["thumb"], "path" => "/test/thumb.jpg" }
    ]

    api_response = {
      "id" => "JOB123", "status" => "DONE", "progress" => 1.0,
      "lastModified" => Time.current.iso8601,
      "output" => output,
      "outputParams" => { "duration" => 120.0 },
      "messages" => []
    }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [api_response], [], ref_id: "REF123")

    expect_method_called_on(
      object: Folio::CraMediaCloud::Api,
      method: :new,
      return_value: api_mock
    ) do
      Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
    end

    video.reload
    assert_equal "full_media_processed", video.remote_services_data["processing_state"]
    assert_equal 100.0, video.remote_services_data["progress_percentage"]
    assert_equal "ready", video.aasm_state
  end

  test "FAILED job transitions to processing_failed and schedules retry on first failure" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "processing_state" => "full_media_processing",
      "reference_id" => "REF123",
      "progress_percentage" => 45.0
    ))

    api_response = {
      "id" => "JOB123", "status" => "FAILED",
      "lastModified" => Time.current.iso8601,
      "messages" => [
        { "type" => "ERROR", "message" => "filesize mismatch" }
      ]
    }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [api_response], [], ref_id: "REF123")

    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CreateMediaJob do
      expect_method_called_on(
        object: Folio::CraMediaCloud::Api,
        method: :new,
        return_value: api_mock
      ) do
        Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
      end
    end

    video.reload
    assert_equal "processing_failed", video.aasm_state
    assert_nil video.remote_services_data["progress_percentage"]
    assert_equal "filesize mismatch", video.remote_services_data["error_message"]
    assert_equal 1, video.remote_services_data["retry_count"]
    assert video.remote_services_data["retry_scheduled_at"].present?
  end

  test "FAILED job on second failure is final — no retry scheduled" do
    video = create_test_video_in_processing_state
    video.update!(remote_services_data: video.remote_services_data.merge(
      "processing_state" => "full_media_processing",
      "reference_id" => "REF123",
      "retry_count" => 1
    ))

    api_response = {
      "id" => "JOB123", "status" => "FAILED",
      "lastModified" => Time.current.iso8601,
      "messages" => [
        { "type" => "ERROR", "message" => "filesize mismatch again" }
      ]
    }

    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [api_response], [], ref_id: "REF123")

    assert_no_enqueued_jobs only: Folio::CraMediaCloud::CreateMediaJob do
      expect_method_called_on(
        object: Folio::CraMediaCloud::Api,
        method: :new,
        return_value: api_mock
      ) do
        Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
      end
    end

    video.reload
    assert_equal "processing_failed", video.aasm_state
    assert_equal 2, video.remote_services_data["retry_count"]
    assert_nil video.remote_services_data["retry_scheduled_at"]
  end

  private
    def create_test_video_in_processing_state
      video = TestVideoFile.new(site: get_any_site)
      video.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
      video.dont_run_after_save_jobs = true

      expect_method_called_on(object: video, method: :create_full_media) do
        video.save!
      end

      video.update!(remote_services_data: video.remote_services_data.merge(
        "service" => "cra_media_cloud",
        "processing_state" => "full_media_processing"
      ))
      video
    end
end

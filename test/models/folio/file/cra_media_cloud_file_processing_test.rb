# frozen_string_literal: true

require "test_helper"

# Integration tests for AASM state machine + Folio::CraMediaCloud::FileProcessing concern.
# Verifies that the full state machine works correctly when the CRA concern is included.
class Folio::File::CraMediaCloudFileProcessingTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::CraMediaCloud::FileProcessing
  end

  # --- process! triggers CRA encoding ---

  test "process! transitions to processing and enqueues CreateMediaJob" do
    video = build_saved_video
    # after_commit :process! fires during build_saved_video's save!, leaving state = "processing".
    # Reset to unprocessed so we can test a clean process! transition.
    video.update_column(:aasm_state, "unprocessed")

    video.stub(:regenerate_thumbnails, nil) do
      assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CreateMediaJob do
        video.process!
      end
    end

    video.reload
    assert_equal "processing", video.aasm_state
    assert_equal "cra_media_cloud", video.remote_services_data["service"]
    assert_equal "enqueued", video.remote_services_data["processing_state"]
    assert video.remote_services_data["encoding_generation"].present?,
           "encoding_generation must be set so CheckProgressJob can detect stale jobs"
  end

  test "process_attached_file sets a new encoding_generation each time" do
    video = build_saved_video
    # Reset state (after_commit :process! fired during save!, leaving state = "processing")
    video.update_column(:aasm_state, "unprocessed")
    video.update!(remote_services_data: { "encoding_generation" => 999 })

    video.stub(:regenerate_thumbnails, nil) do
      video.process!
    end

    video.reload
    assert_not_equal 999, video.remote_services_data["encoding_generation"],
                     "encoding_generation should change on re-encode"
  end

  # --- AASM state transitions ---

  test "processing_done! transitions processing to ready" do
    video = build_saved_video
    video.update_column(:aasm_state, "processing")

    video.processing_done!

    assert_equal "ready", video.reload.aasm_state
  end

  test "processing_failed! transitions processing to processing_failed" do
    video = build_saved_video
    video.update_column(:aasm_state, "processing")

    video.processing_failed!

    assert_equal "processing_failed", video.reload.aasm_state
  end

  test "retry_processing! transitions processing_failed back to processing" do
    video = build_saved_video
    video.update_column(:aasm_state, "processing_failed")

    video.retry_processing!

    assert_equal "processing", video.reload.aasm_state
  end

  # --- destroy_attached_file enqueues DeleteMediaJob ---

  test "destroy_attached_file enqueues DeleteMediaJob when remote_id is present" do
    video = build_saved_video
    video.update!(remote_services_data: {
      "remote_id" => "JOB123",
      "reference_id" => "REF456"
    })

    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::DeleteMediaJob do
      video.destroy_attached_file
    end
  end

  test "destroy_attached_file does nothing when no remote_id or reference_id" do
    video = build_saved_video
    video.update!(remote_services_data: {})

    assert_no_enqueued_jobs only: Folio::CraMediaCloud::DeleteMediaJob do
      video.destroy_attached_file
    end
  end

  private
    def build_saved_video
      video = TestVideoFile.new(site: get_any_site)
      video.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
      video.dont_run_after_save_jobs = true

      expect_method_called_on(object: video, method: :create_full_media) do
        video.save!
      end

      video
    end
end

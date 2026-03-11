# frozen_string_literal: true

require "test_helper"

class Folio::MediaFileProcessingBaseTest < ActiveSupport::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::CraMediaCloud::FileProcessing
  end

  test "encoding_generation is set during process_attached_file" do
    video = TestVideoFile.new(site: get_any_site)
    video.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video.dont_run_after_save_jobs = true

    # save! triggers after_commit -> process! -> process_attached_file
    # which sets encoding_generation; stub create_full_media to stop the chain
    freeze_time = Time.current
    travel_to freeze_time do
      expect_method_called_on(object: video, method: :create_full_media) do
        video.save!
      end
    end

    assert video.processing?
    assert_equal freeze_time.to_i, video.encoding_generation
  end

  test "encoding_generation returns nil when not set" do
    # Test the accessor on a model without processing
    video = TestVideoFile.new
    video.remote_services_data = {}

    assert_nil video.encoding_generation
  end

  test "encoding_generation survives remote_services_data merge" do
    video = TestVideoFile.new(site: get_any_site)
    video.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video.dont_run_after_save_jobs = true

    # save! triggers process_attached_file which sets encoding_generation
    expect_method_called_on(object: video, method: :create_full_media) do
      video.save!
    end

    original_generation = video.encoding_generation
    assert_not_nil original_generation

    # Merge additional data (simulating what CreateMediaJob does)
    video.remote_services_data.merge!({
      "service" => "cra_media_cloud",
      "reference_id" => "REF123",
      "processing_state" => "full_media_processing"
    })
    video.save!

    # encoding_generation should still be there
    video.reload
    assert_equal original_generation, video.encoding_generation
  end

  test "encoding_generation is set even when model has validation errors" do
    video = TestVideoFile.new(site: get_any_site)
    video.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video.dont_run_after_save_jobs = true

    expect_method_called_on(object: video, method: :create_full_media) do
      video.save!
    end

    # Simulate a video that would fail validation (e.g. ffprobe failed, dimensions missing)
    video.update_columns(file_width: nil, file_height: nil)
    video.reload

    assert_not video.valid?, "video should be invalid without dimensions"

    # process_attached_file uses update_columns, so it should succeed despite invalid model
    freeze_time = Time.current
    travel_to freeze_time do
      video.send(:update_remote_services_data, {
        "processing_step_started_at" => Time.current,
        "encoding_generation" => freeze_time.to_i
      })
    end

    video.reload
    assert_equal freeze_time.to_i, video.encoding_generation
  end

  test "create_full_media preserves encoding_generation" do
    video = TestVideoFile.new(site: get_any_site)
    video.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video.dont_run_after_save_jobs = true
    video.save!

    # Set encoding_generation like process_attached_file does
    video.update_columns(aasm_state: "processing")
    video.send(:update_remote_services_data, {
      "processing_step_started_at" => Time.current,
      "encoding_generation" => 12345
    })

    # create_full_media should merge in service/state without losing encoding_generation
    video.create_full_media

    video.reload
    assert_equal 12345, video.encoding_generation
    assert_equal "cra_media_cloud", video.remote_services_data["service"]
    assert_equal "enqueued", video.remote_services_data["processing_state"]
  end
end

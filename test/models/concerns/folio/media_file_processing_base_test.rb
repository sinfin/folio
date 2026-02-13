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
end

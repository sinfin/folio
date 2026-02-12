# frozen_string_literal: true

require "test_helper"

class Folio::CraMediaCloud::CreateMediaJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::CraMediaCloud::FileProcessing
  end

  test "passes encoding_generation to CheckProgressJob when uploading" do
    video = create_test_video_in_processing_state
    generation_value = 1700000000
    video.update!(remote_services_data: video.remote_services_data.merge(
      "encoding_generation" => generation_value
    ))

    # Mock S3 metadata for reference_id generation
    s3_metadata_mock = Struct.new(:etag).new('"abc12345def67890"')
    s3_datastore_mock = Minitest::Mock.new
    storage_mock = Minitest::Mock.new
    storage_mock.expect(:head_object, s3_metadata_mock, [String, String])
    s3_datastore_mock.expect(:root_path, "uploads")
    s3_datastore_mock.expect(:storage, storage_mock)

    # Mock encoder
    encoder_mock = Minitest::Mock.new
    encoder_mock.expect(:upload_file, nil, [video], profile_group: nil, reference_id: String)

    # Mock API for existing job check
    api_mock = Minitest::Mock.new
    api_mock.expect(:get_jobs, [], [], ref_id: String)

    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
      Dragonfly.app.stub(:datastore, s3_datastore_mock) do
        Folio::CraMediaCloud::Encoder.stub(:new, encoder_mock) do
          Folio::CraMediaCloud::Api.stub(:new, api_mock) do
            Folio::CraMediaCloud::CreateMediaJob.perform_now(video)
          end
        end
      end
    end

    # Verify encoding_generation is preserved in remote_services_data
    video.reload
    assert_equal generation_value, video.encoding_generation,
      "encoding_generation should be preserved through CreateMediaJob"
  end

  private
    def create_test_video_in_processing_state
      video = TestVideoFile.new(site: get_any_site)
      video.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
      video.dont_run_after_save_jobs = true

      # Stub create_full_media to prevent the full processing chain during save
      expect_method_called_on(object: video, method: :create_full_media) do
        video.save!
      end

      # Set desired initial state (merge to preserve encoding_generation from process_attached_file)
      video.update!(remote_services_data: video.remote_services_data.merge(
        "service" => "cra_media_cloud",
        "processing_state" => "full_media_processing"
      ))
      video
    end
end

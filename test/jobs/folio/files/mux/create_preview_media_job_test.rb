# frozen_string_literal: true

require "test_helper"

class Folio::Files::Mux::CreatePreviewMediaJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::Mux::FileProcessing
  end

  ResponseDataStruct = Struct.new(:id, :status, :duration)
  ResponseStruct = Struct.new(:data)

  test "calls api and updates remote_services_data" do
    tv_file = TestVideoFile.new
    tv_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    assert_enqueued_jobs 1, only: Folio::Files::Mux::CreateFullMediaJob do
      tv_file.save!
    end
    assert tv_file.processing?

    tv_file.remote_services_data.merge!({ "processing_state" => "full_media_processed",
                                          "remote_key" => "bflmpsvz" })

    response = ResponseStruct.new(ResponseDataStruct.new(12, "preparing", 35))
    api_mock = Minitest::Mock.new
    api_mock.expect(:create_media, response, [], preview: true)
    api_mock.expect(:==, false, [:not_passed])

    assert_enqueued_jobs 1, only: Folio::Files::Mux::CheckProgressJob do
      # assert_enqueued_jobs 1, only: Folio::Files::Mux::DeleteMediaJob
      expect_method_called_on(object: Folio::Mux::Api,
                                      method: :new,
                                      args: [tv_file],
                                      return_value: api_mock) do
        Folio::Files::Mux::CreatePreviewMediaJob.perform_now(tv_file)
      end
    end
    api_mock.verify



    assert_equal "mux", tv_file.reload.processing_service
    assert_equal response.data.id, tv_file.remote_preview_key
    assert_equal "preview_media_processing", tv_file.processing_state, tv_file.remote_services_data
    assert tv_file.processing?
  end
end

# frozen_string_literal: true

require "test_helper"

class Folio::Files::Mux::CreateFullMediaJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::ProcessedByMux
  end

  ResponseDataStruct = Struct.new(:id, :status, :duration)
  ResponseStruct = Struct.new(:data)

  # actually it is:
  # MuxRuby::AssetResponse:0x00007f4c6c0903e8
  # @data=
  #  #<MuxRuby::Asset:0x00007f4c6c097b48
  #   @id="fsdfsdk3980736",

  test "calls api and updates remote_services_data" do
    tv_file = TestVideoFile.new
    tv_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    assert_enqueued_jobs 1, only: Folio::Files::Mux::CreateFullMediaJob do
      tv_file.save!
    end

    assert tv_file.processing?, "AASM state #{tv_file.aasm_state}"
    assert_equal "enqueued", tv_file.processing_state, tv_file.remote_services_data
    assert_equal "mux", tv_file.processing_service

    response = ResponseStruct.new(ResponseDataStruct.new(12, "preparing", 35))
    api_mock = Minitest::Mock.new
    api_mock.expect(:create_media, response, [])
    api_mock.expect(:==, false, [:not_passed])

    assert_enqueued_jobs 1, only: Folio::Files::Mux::CheckProgressJob do
      # assert_enqueued_jobs 1, only: Folio::Files::Mux::DeleteMediaJob
      expect_method_called_on(object: Folio::Mux::Api,
                                      method: :new,
                                      args: [tv_file],
                                      return_value: api_mock) do
        Folio::Files::Mux::CreateFullMediaJob.perform_now(tv_file)
      end
    end
    api_mock.verify

    assert_equal "mux", tv_file.reload.processing_service
    assert_equal response.data.id, tv_file.remote_key
    assert_equal "full_media_processing", tv_file.processing_state, tv_file.remote_services_data
    assert tv_file.processing?
  end
end

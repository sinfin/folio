# frozen_string_literal: true

require "test_helper"

class Folio::JwPlayer::CreatePreviewMediaJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::JwPlayer::FileProcessing
  end

  test "calls api and updates remote_services_data" do
    tv_file = TestVideoFile.new(site: get_any_site)
    tv_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    assert_enqueued_jobs 1, only: Folio::JwPlayer::CreateFullMediaJob do
      tv_file.save!
    end
    assert tv_file.processing?

    tv_file.remote_services_data.merge!({ "processing_state" => "full_media_processed",
                                          "remote_key" => "bflmpsvz" })

    response = { "status" => "processing", "id" => "remote_key_asdskljdaslk" }
    api_mock = Minitest::Mock.new
    api_mock.expect(:create_media, response, [], preview: true)
    api_mock.expect(:==, false, [:not_passed])

    assert_enqueued_jobs 1, only: Folio::JwPlayer::CheckProgressJob do
      # assert_enqueued_jobs 1, only: Folio::JwPlayer::DeleteMediaJob
      expect_method_called_on(object: Folio::JwPlayer::Api,
                                      method: :new,
                                      args: [tv_file],
                                      return_value: api_mock) do
        Folio::JwPlayer::CreatePreviewMediaJob.perform_now(tv_file)
      end
    end
    api_mock.verify



    assert_equal "jw_player", tv_file.reload.processing_service
    assert_equal response["id"], tv_file.remote_preview_key
    assert_equal "preview_media_processing", tv_file.processing_state, tv_file.remote_services_data
    assert tv_file.processing?
  end
end

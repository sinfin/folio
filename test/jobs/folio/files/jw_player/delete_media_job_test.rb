# frozen_string_literal: true

require "test_helper"

class Folio::Files::JwPlayer::DeleteMediaJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::ProcessedByJwPlayer
  end

  test "calls api and updates remote_services_data" do
    tv_file = TestVideoFile.new
    tv_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    assert_enqueued_jobs 1, only: Folio::Files::JwPlayer::CreateFullMediaJob do
      tv_file.save!
    end
    assert tv_file.processing?

    tv_file.remote_services_data.merge!({ "processing_state" => "preview_media_processed",
                                          "remote_key" => "bflmpsvz",
                                          "remote_preview_key" => "hchkrdtn" })

    response = { "status" => "deleted" } # TODO: questimated, verify on real example

    api_mock = Minitest::Mock.new
    api_mock.expect(:delete_media, response, [], preview: false)
    api_mock.expect(:delete_media, response, [], preview: true)

    Folio::JwPlayer::Api.stub(:new, api_mock) do
      Folio::Files::JwPlayer::DeleteMediaJob.perform_now(tv_file)
    end
    api_mock.verify
  end
end

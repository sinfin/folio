# frozen_string_literal: true

require "test_helper"

class Folio::Files::JwPlayer::DeleteMediaJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::JwPlayer::FileProcessing
  end

  test "calls api and updates remote_services_data" do
    remote_key = "retkjltretjl"
    response = nil

    api_mock = Minitest::Mock.new
    api_mock.expect(:delete_media, response, [])
    api_mock.expect(:==, false, [:not_passed])

    expect_method_called_on(object: Folio::JwPlayer::Api,
      method: :new,
      args: [Folio::Files::JwPlayer::DeleteMediaJob::MFileStruct.new(remote_key)],
      return_value: api_mock) do
      Folio::Files::JwPlayer::DeleteMediaJob.perform_now(remote_key)
    end
    api_mock.verify
  end
end

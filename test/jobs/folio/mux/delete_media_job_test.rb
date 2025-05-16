# frozen_string_literal: true

require "test_helper"

class Folio::Mux::DeleteMediaJobTest < ActiveJob::TestCase
  class TestVideoFile < Folio::File::Video
    include Folio::Mux::FileProcessing
  end

  test "calls api and updates remote_services_data" do
    remote_key = "retkjltretjl"
    response = "null"

    api_mock = Minitest::Mock.new
    api_mock.expect(:delete_media, response, [])
    api_mock.expect(:==, false, [:not_passed])

    expect_method_called_on(object: Folio::Mux::Api,
      method: :new,
      args: [Folio::Mux::DeleteMediaJob::MFileStruct.new(remote_key)],
      return_value: api_mock) do
      Folio::Mux::DeleteMediaJob.perform_now(remote_key)
    end

    assert api_mock.verify
  end
end

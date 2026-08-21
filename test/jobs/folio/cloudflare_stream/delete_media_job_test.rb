# frozen_string_literal: true

require "test_helper"

class Folio::CloudflareStream::DeleteMediaJobTest < ActiveJob::TestCase
  test "deletes Stream video by identifier" do
    api = RecordingApi.new

    Folio::CloudflareStream::Api.stub(:new, api) do
      Folio::CloudflareStream::DeleteMediaJob.perform_now("stream-1")
    end

    assert_equal "stream-1", api.deleted_identifier
  end

  test "skips blank identifier without initializing API" do
    api_called = false

    Folio::CloudflareStream::Api.stub(:new, -> { api_called = true }) do
      Folio::CloudflareStream::DeleteMediaJob.perform_now(nil)
      Folio::CloudflareStream::DeleteMediaJob.perform_now("")
    end

    assert_not api_called
  end

  test "logs API errors without raising" do
    api = FailingApi.new
    log_io = StringIO.new
    logger = ActiveSupport::Logger.new(log_io)

    Rails.stub(:logger, logger) do
      Folio::CloudflareStream::Api.stub(:new, api) do
        assert_nothing_raised do
          Folio::CloudflareStream::DeleteMediaJob.perform_now("stream-1")
        end
      end
    end

    assert_includes log_io.string, "[CloudflareStream::DeleteMediaJob] delete failed"
  end

  private
    class RecordingApi
      attr_reader :deleted_identifier

      def delete(identifier)
        @deleted_identifier = identifier
      end
    end

    class FailingApi
      def delete(_identifier)
        raise Folio::CloudflareStream::Api::Error, "delete failed"
      end
    end
end

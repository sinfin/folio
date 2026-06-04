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

  test "logs not found API errors without raising" do
    api = FailingApi.new(Folio::CloudflareStream::Api::Error.new("not found", status_code: 404))
    log_io = StringIO.new
    logger = ActiveSupport::Logger.new(log_io)

    Rails.stub(:logger, logger) do
      Folio::CloudflareStream::Api.stub(:new, api) do
        assert_nothing_raised do
          Folio::CloudflareStream::DeleteMediaJob.perform_now("stream-1")
        end
      end
    end

    assert_includes log_io.string, "[CloudflareStream::DeleteMediaJob] Stream video already deleted: not found"
  end

  test "raises non-not-found API errors for retry" do
    api = FailingApi.new(Folio::CloudflareStream::Api::Error.new("delete failed", status_code: 500))
    log_io = StringIO.new
    logger = ActiveSupport::Logger.new(log_io)

    Rails.stub(:logger, logger) do
      Folio::CloudflareStream::Api.stub(:new, api) do
        assert_raises(Folio::CloudflareStream::Api::Error) do
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
      def initialize(error)
        @error = error
      end

      def delete(_identifier)
        raise @error
      end
    end
end

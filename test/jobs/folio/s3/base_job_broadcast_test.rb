# frozen_string_literal: true

require "test_helper"

class Folio::S3::BaseJobBroadcastTest < ActiveJob::TestCase
  test "perform broadcasts success for already processed missing S3 upload" do
    file = create(:folio_file_image)
    s3_path = "tmp_folio_file_uploads/session/test/already-processed/test.jpg"
    job = Folio::S3::CreateFileJob.new
    published_payloads = []

    Rails.cache.write(job.send(:processed_upload_cache_key, s3_path),
                      { "file_id" => file.id, "file_type" => file.class.to_s, "replacing_file" => false },
                      expires_in: 1.hour)

    MessageBus.stub(:publish, ->(_channel, payload, client_ids:) { published_payloads << [payload, client_ids] }) do
      job.perform(s3_path:,
                  type: file.class.to_s,
                  message_bus_client_id: "test-client-123")
    end

    payload, client_ids = published_payloads.last
    data = JSON.parse(payload).fetch("data")

    assert_equal ["test-client-123"], client_ids
    assert_equal "success", data.fetch("type")
    assert_equal file.id, data.fetch("file_id")
    assert_equal s3_path, data.fetch("s3_path")
  ensure
    Rails.cache.delete(job.send(:processed_upload_cache_key, s3_path)) if job && s3_path
  end

  test "perform logs diagnostic details when S3 upload is missing" do
    job = Folio::S3::CreateFileJob.new
    s3_path = "tmp_folio_file_uploads/session/test/missing/test.jpg"
    log_messages = []
    logger = Class.new do
      define_method(:initialize) { |messages| @messages = messages }
      define_method(:warn) { |message| @messages << message }
    end.new(log_messages)

    Rails.stub(:logger, logger) do
      job.perform(s3_path:,
                  type: "Folio::File::Image",
                  message_bus_client_id: "test-client-123",
                  web_session_id: "session-123",
                  user_id: 456)
    end

    log_message = log_messages.find { |message| message.include?("File not found on S3") }

    assert log_message
    assert_includes log_message, s3_path
    assert_includes log_message, "Folio::File::Image"
    assert_includes log_message, "session-123"
    assert_includes log_message, "456"
    assert_includes log_message, "test-client-123"
  end

  # Test that broadcast methods handle nil file safely (file&.id instead of file.id)
  test "broadcast_error handles nil file without raising" do
    job = Folio::S3::CreateFileJob.new
    # Set message_bus_client_id so broadcast actually runs
    job.instance_variable_set(:@message_bus_client_id, "test-client-123")

    # Should not raise NoMethodError when file is nil
    assert_nothing_raised do
      job.send(:broadcast_error, s3_path: "test/path", file: nil, error: StandardError.new("test error"), file_type: "Folio::File::Video")
    end
  end

  test "broadcast_replace_error handles nil file without raising" do
    job = Folio::S3::CreateFileJob.new
    job.instance_variable_set(:@message_bus_client_id, "test-client-123")

    # Should not raise NoMethodError when file is nil
    assert_nothing_raised do
      job.send(:broadcast_replace_error, s3_path: "test/path", file: nil, error: StandardError.new("test error"), file_type: "Folio::File::Video")
    end
  end
end

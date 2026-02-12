# frozen_string_literal: true

require "test_helper"

class Folio::S3::BaseJobBroadcastTest < ActiveJob::TestCase
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

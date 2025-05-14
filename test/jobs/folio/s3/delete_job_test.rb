# frozen_string_literal: true

require "test_helper"

class Folio::S3::DeleteJobTest < ActiveJob::TestCase
  class ClassWithS3Client
    include Folio::S3::Client # it is mixin
  end

  setup do
    @instance = ClassWithS3Client.new
  end

  test "perform" do
    fixture_file_path = Folio::Engine.root.join("test", "fixtures", "folio", "empty.pdf")

    s3_path = "s3_delete/empty.pdf"
    @instance.test_aware_s3_upload(s3_path:, file: File.open(fixture_file_path))

    assert @instance.test_aware_s3_exists?(s3_path:)

    perform_enqueued_jobs do
      Folio::S3::DeleteJob.perform_now(s3_path:)
    end

    assert_not @instance.test_aware_s3_exists?(s3_path:)
  end
end

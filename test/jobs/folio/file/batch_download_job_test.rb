# frozen_string_literal: true

require "test_helper"

class Folio::File::BatchDownloadJobTest < ActiveJob::TestCase
  class ClassWithS3Client
    include Folio::S3::Client
  end

  test "perform" do
    s3_path = "test/s3_batch_download_job_test/images.zip"

    @instance = ClassWithS3Client.new

    if @instance.test_aware_s3_exists?(s3_path:)
      @instance.test_aware_s3_delete(s3_path:)
    end

    file_ids = [create(:folio_file_image).id]

    Folio::S3::DeleteJob.stub(:perform_later, nil) do
      Folio::File::BatchDownloadJob.perform_now(s3_path:,
                                                file_ids:,
                                                user_id: create(:folio_user, :superadmin).id,
                                                file_class_name: "Folio::File::Image",
                                                site_id: get_any_site.id)

      assert @instance.test_aware_s3_exists?(s3_path:)
      @instance.test_aware_s3_delete(s3_path:)
    end
  end
end

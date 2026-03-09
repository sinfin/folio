# frozen_string_literal: true

require "test_helper"

class Folio::S3::CreateFileJobTest < ActiveJob::TestCase
  include Folio::S3::Client

  test "video upload falls back to download flow for local file system" do
    # In test env with FileDataStore, video upload should use the standard download path
    # (S3 copy path is only for actual S3 storage)
    s3_path = "test_video.mp4"

    # Create a temp file simulating S3 uploaded file
    source_path = "#{Folio::S3::Client::LOCAL_TEST_PATH}/#{s3_path}"
    FileUtils.mkdir_p(File.dirname(source_path))
    fixture_path = Folio::Engine.root.join("test/fixtures/folio/blank.mp4").to_s
    FileUtils.cp(fixture_path, source_path)

    site = get_any_site

    Folio::S3::CreateFileJob.perform_now(
      s3_path: s3_path,
      type: "Folio::File::Video",
      attributes: { site_id: site.id }
    )

    # File should be created successfully via download path
    created_video = Folio::File::Video.last
    assert created_video.present?, "Video should be created"
    assert created_video.file_uid.present?, "Video should have file_uid"
    assert created_video.file_name.present?, "Video should have file_name"
  ensure
    FileUtils.rm_f(source_path) if source_path
  end
end

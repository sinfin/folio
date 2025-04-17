# frozen_string_literal: true

class Folio::Aws::CheckMetadataJob < Folio::Aws::BaseCheckJob

  # 30 seconds check
  retries(max: 6)

  def do_check(file)
    iso_time = file.metadata["metafileTimestamp"]
    metafile_time_stamp = iso_time ? Time.parse(iso_time) : Time.at(0)

    file_response = Folio::Aws::S3::FileService.get(
      file.full_s3_path(file.class::AwsS3File::METADATA),
      if_modified_since: metafile_time_stamp
    )

    file.process_metadata(JSON.parse(file_response.body.read), file_response.last_modified.utc.iso8601)

    true
  rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotModified
    # File is not on S3 yet
    false
  end
end

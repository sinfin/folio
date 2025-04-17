# frozen_string_literal: true

class Folio::Aws::CheckRekognitionJob < Folio::Aws::BaseCheckJob

  # 2 minutes check
  retries(max: 24)

  def do_check(file)
    file_response = Folio::Aws::S3::FileService.get(
      file.full_s3_path(file.class::AwsS3File::REKOGNITION),
      if_modified_since: Time.parse(file.metadata["metafileTimestamp"])
    )

    file.process_rekognition(JSON.parse(file_response.body.read), file_response.last_modified.utc.iso8601)

    true
  rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotModified
    # File is not on S3 yet
    false
  end
end

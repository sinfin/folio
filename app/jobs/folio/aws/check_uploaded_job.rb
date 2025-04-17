# frozen_string_literal: true

class Folio::Aws::CheckUploadedJob < Folio::Aws::BaseCheckJob

  # 2 minutes
  retries(max: 24)

  def do_check(file)
    return false unless Folio::Aws::S3::FileService.exist?(file.full_s3_path)

    file.process_uploaded

    true
  end
end

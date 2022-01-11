# frozen_string_literal: true

module Folio::S3Client
  TEST_PATH = "/tmp/folio_tmp_user_photo_uploads"

  def s3_client
    @s3_client ||= Aws::S3::Client.new(region: ENV.fetch("S3_REGION"),
                                       credentials: Aws::Credentials.new(ENV.fetch("AWS_ACCESS_KEY_ID"),
                                                                         ENV.fetch("AWS_SECRET_ACCESS_KEY")))
  end

  def s3_presigner
    @s3_presigner ||= Aws::S3::Presigner.new(client: s3_client)
  end

  def test_aware_presign_url(s3_path)
    if Rails.env.test?
      "https://dummy-s3-bucket.com/#{s3_path}"
    else
      s3_presigner.presigned_url(:put_object, bucket: ENV.fetch("S3_BUCKET_NAME"), key: s3_path)
    end
  end

  def test_aware_s3_exists?(s3_path)
    if Rails.env.test?
      File.exist?("#{TEST_PATH}/#{s3_path}")
    else
      s3_exists?(s3_path)
    end
  end

  def test_aware_download_from_s3(s3_path, local_path)
    if Rails.env.test?
      FileUtils.cp("#{TEST_PATH}/#{s3_path}", local_path)
    else
      download_from_s3(s3_path, local_path)
    end
  end

  def test_aware_s3_exists?(s3_path)
    if Rails.env.test?
      File.exist?("#{TEST_PATH}/#{s3_path}")
    else
      s3_exists?(s3_path)
    end
  end

  def test_aware_s3_delete(s3_path)
    if test_aware_s3_exists?(s3_path)
      if Rails.env.test?
        FileUtils.rm("#{TEST_PATH}/#{s3_path}")
      else
        s3_delete(s3_path)
      end
    end
  end
end

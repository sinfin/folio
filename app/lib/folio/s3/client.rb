# frozen_string_literal: true

module Folio::S3::Client
  LOCAL_TEST_PATH = "/tmp/folio_tmp_user_photo_uploads"
  S3_TEST_PATH = "test_files"

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
    region: ENV.fetch("S3_REGION"),
    credentials: Aws::Credentials.new(
      ENV.fetch("AWS_ACCESS_KEY_ID"),
      ENV.fetch("AWS_SECRET_ACCESS_KEY"),
      ENV.fetch("AWS_SESSION_TOKEN", nil)
    )
  )
  end

  def s3_presigner
    @s3_presigner ||= Aws::S3::Presigner.new(client: s3_client)
  end

  def s3_bucket
    @s3_bucket ||= ENV.fetch("S3_BUCKET_NAME")
  end

  def s3_ls(prefix:, max_keys: 1000)
    s3_client.list_objects(
      bucket: s3_bucket,
      prefix:,
      max_keys:,
    )
  end

  def test_aware_presign_url(s3_path:)
    if use_local_file_system?
      "https://dummy-s3-bucket.com/#{s3_path}"
    else
      s3_presigner.presigned_url(:put_object, bucket: s3_bucket, key: test_aware_s3_path(s3_path))
    end
  end

  def test_aware_download_from_s3(s3_path:, local_path:)
    if use_local_file_system?
      FileUtils.mkdir_p(File.dirname(test_aware_s3_path(s3_path)))
      FileUtils.cp(test_aware_s3_path(s3_path), local_path)
    else
      s3_client.get_object(bucket: s3_bucket,
                           key: test_aware_s3_path(s3_path),
                           response_target: local_path,
                           response_content_type: "image/jpeg")
    end
  end

  def test_aware_s3_exists?(s3_path:)
    if use_local_file_system?
      File.exist?(test_aware_s3_path(s3_path))
    else
      begin
        s3_client.head_object(
          bucket: s3_bucket,
          key: test_aware_s3_path(s3_path)
        )
        true
      rescue Aws::S3::Errors::NotFound
        false
      end
    end
  end

  def test_aware_s3_delete(s3_path:)
    if test_aware_s3_exists?(s3_path:)
      if use_local_file_system?
        FileUtils.rm(test_aware_s3_path(s3_path))
      else
        s3_client.delete_object(
          bucket: s3_bucket,
          key: test_aware_s3_path(s3_path)
        )
      end
    end
  end

  def test_aware_s3_upload(s3_path:, file:, acl: "private")
    if use_local_file_system?
      FileUtils.mkdir_p(File.dirname(test_aware_s3_path(s3_path)))
      FileUtils.cp(file.path, test_aware_s3_path(s3_path))
    else
      s3_client.put_object(
        bucket: s3_bucket,
        key: test_aware_s3_path(s3_path),
        body: file,
        acl:,
      )
    end
  end

  private
    def use_local_file_system?
      @use_local_file_system ||= Dragonfly.app.datastore.is_a?(Dragonfly::FileDataStore)
    end

    def test_aware_s3_path(s3_path)
      return s3_path unless Rails.env.test?

      if use_local_file_system?
        "#{LOCAL_TEST_PATH}/#{s3_path}"
      else
        "#{S3_TEST_PATH}/#{s3_path}"
      end
    end
end

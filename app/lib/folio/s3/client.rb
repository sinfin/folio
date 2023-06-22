# frozen_string_literal: true

module Folio::S3::Client
  TEST_PATH = "/tmp/folio_tmp_user_photo_uploads"

  def s3_client
    @s3_client ||= Aws::S3::Client.new(region: ENV.fetch("S3_REGION"),
                                       credentials: Aws::Credentials.new(ENV.fetch("AWS_ACCESS_KEY_ID"),
                                                                         ENV.fetch("AWS_SECRET_ACCESS_KEY")))
  end

  def s3_presigner
    @s3_presigner ||= Aws::S3::Presigner.new(client: s3_client)
  end

  def s3_bucket
    @s3_bucket ||= ENV.fetch("S3_BUCKET_NAME")
  end

  def test_aware_presign_url(s3_path)
    if Rails.env.test?
      "https://dummy-s3-bucket.com/#{s3_path}"
    else
      s3_presigner.presigned_url(:put_object, bucket: s3_bucket, key: s3_path)
    end
  end

  def test_aware_download_from_s3(s3_path, local_path)
    if Rails.env.test?
      test_path = "#{TEST_PATH}/#{s3_path}"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(test_path, local_path)
    else
      s3_client.get_object(bucket: s3_bucket,
                           key: s3_path,
                           response_target: local_path,
                           response_content_type: "image/jpeg")
    end
  end

  def test_aware_s3_exists?(s3_path)
    if Rails.env.test?
      File.exist?("#{TEST_PATH}/#{s3_path}")
    else
      begin
        s3_client.head_object(
          bucket: s3_bucket,
          key: s3_path
        )
        true
      rescue Aws::S3::Errors::NotFound
        false
      end
    end
  end

  def test_aware_s3_delete(s3_path)
    if test_aware_s3_exists?(s3_path)
      if Rails.env.test?
        FileUtils.rm("#{TEST_PATH}/#{s3_path}")
      else
        s3_client.delete_object(
          bucket: s3_bucket,
          key: s3_path
        )
      end
    end
  end

  def s3_multipart_upload(s3_path:, target_path:)
    multipart_upload = s3_client.create_multipart_upload(bucket: s3_bucket, key: target_path)

    s3_structs_for_parts = s3_client.list_objects(bucket: s3_bucket, prefix: "#{s3_path}.").contents

    parts = s3_structs_for_parts.each_with_index
                                .map do |s3_struct_for_part, i|
      copy_response = s3_client.upload_part_copy(bucket: s3_bucket,
                                                 copy_source: "#{s3_bucket}/#{s3_struct_for_part.key}",
                                                 key: target_path,
                                                 part_number: i + 1,
                                                 upload_id: multipart_upload.upload_id)

      { etag: copy_response.copy_part_result.etag, part_number: i + 1 }
    end

    s3_client.complete_multipart_upload(bucket: s3_bucket,
                                        key: target_path,
                                        multipart_upload: { parts: },
                                        upload_id: multipart_upload.upload_id)
  end
end

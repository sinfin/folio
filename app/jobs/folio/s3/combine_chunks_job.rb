# frozen_string_literal: true

class Folio::S3::CombineChunksJob < Folio::S3::BaseJob
  def perform_for_valid(s3_path:, klass:, existing_id:, web_session_id:, user_id:, attributes:)
    multipart_upload = s3_client.create_multipart_upload(bucket: s3_bucket, key: s3_path)

    s3_structs_for_parts = s3_client.list_objects(bucket: s3_bucket, prefix: "#{s3_path}.").contents

    parts = s3_structs_for_parts.each_with_index
                                .map do |s3_struct_for_part, i|
      copy_response = s3_client.upload_part_copy(bucket: s3_bucket,
                                                 copy_source: "#{s3_bucket}/#{s3_struct_for_part.key}",
                                                 key: s3_path,
                                                 part_number: i + 1,
                                                 upload_id: multipart_upload.upload_id)

      { etag: copy_response.copy_part_result.etag, part_number: i + 1 }
    end

    s3_client.complete_multipart_upload(bucket: s3_bucket,
                                        key: s3_path,
                                        multipart_upload: { parts: },
                                        upload_id: multipart_upload.upload_id)

    Folio::S3::CreateFileJob.perform_later(s3_path:,
                                           type: klass.to_s,
                                           existing_id:,
                                           web_session_id:,
                                           user_id:,
                                           attributes:)
  ensure
    s3_client.list_objects(bucket: s3_bucket, prefix: "#{s3_path}.")
             .contents
             .each { |s3_struct_for_part| test_aware_s3_delete(s3_struct_for_part.key) }
  end

  def self.multipart?
    true
  end
end

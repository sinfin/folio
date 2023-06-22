# frozen_string_literal: true

class Folio::S3::CombineChunksJob < Folio::S3::BaseJob
  def perform_for_valid(s3_path:, klass:, existing_id:, web_session_id:, user_id:, attributes:, from_chunks:)
    s3_multipart_upload(s3_path:, target_path: s3_path)

    Folio::S3::CreateFileJob.perform_later(s3_path:,
                                           type: klass.to_s,
                                           existing_id:,
                                           web_session_id:,
                                           user_id:,
                                           attributes:,
                                           from_chunks: true)
  end

  def self.multipart?
    true
  end
end

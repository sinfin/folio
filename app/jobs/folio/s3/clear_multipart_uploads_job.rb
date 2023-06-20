# frozen_string_literal: true

class Folio::S3::ClearMultipartUploadsJob < Folio::ApplicationJob
  include Folio::S3::Client

  THRESHOLD = 4.hours

  queue_as :default

  if defined?(sidekiq_options)
    sidekiq_options retry: false
  end

  def perform(all: false)
    response = s3_client.list_multipart_uploads(bucket: s3_bucket)

    response.uploads.each do |upload_struct|
      if !all && upload_struct.initiated && upload_struct.initiated > THRESHOLD.ago
        Rails.logger.info "Keeping multipart upload as it hasn't been #{THRESHOLD / 1.hour} yet - #{upload_struct.upload_id} #{upload_struct.key} "
      else
        Rails.logger.info "Aborting multipart upload - #{upload_struct.upload_id} #{upload_struct.key} "
      end

      s3_client.abort_multipart_upload(bucket: s3_bucket,
                                       key: upload_struct.key,
                                       upload_id: upload_struct.upload_id)
    end
  end
end

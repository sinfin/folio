# frozen_string_literal: true

module Folio::CloudflareStream::FileProcessing
  extend ActiveSupport::Concern
  include Folio::MediaFileProcessingBase

  def full_media_job_class
    Folio::CloudflareStream::CreateMediaJob
  end

  def delete_media_job_class
    Folio::CloudflareStream::DeleteMediaJob
  end

  def check_media_processing_job_class
    Folio::CloudflareStream::CheckProgressJob
  end

  def processed_by
    "cloudflare_stream"
  end

  def cloudflare_stream_source_url
    url = file.remote_url(expires: Rails.application.config.folio_cloudflare_stream_source_url_expires_in.from_now)
    Folio::S3.url_rewrite(url)
  end

  def cloudflare_stream_allowed_origins
    Rails.application.config.folio_cloudflare_stream_allowed_origins
  end

  def cloudflare_stream_require_signed_urls?
    Rails.application.config.folio_cloudflare_stream_require_signed_urls
  end

  def destroy_attached_file
    return if remote_services_data["uid"].blank?

    delete_media_job_class.perform_later(remote_services_data["uid"])
  end
end

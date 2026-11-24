# frozen_string_literal: true

class Folio::Video::Providers::DirectFile < Folio::Video::Providers::Base
  def ready?
    video.file_uid.present? && video.ready?
  end

  def sources
    return [] unless ready?
    return [] if source_url.blank?

    [
      {
        src: source_url,
        type: video.file_mime_type.presence || "video/mp4",
        label: "Original",
      }
    ]
  end

  private
    def source_url
      @source_url ||= begin
        url = video.file.remote_url(expires: direct_url_expires_in.from_now)
        Folio::S3.url_rewrite(url)
      end
    end

    def direct_url_expires_in
      Rails.application.config.folio_files_video_direct_url_expires_in
    end
end

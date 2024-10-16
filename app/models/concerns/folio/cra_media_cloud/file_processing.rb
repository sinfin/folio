# frozen_string_literal: true

module Folio::CraMediaCloud::FileProcessing
  extend ActiveSupport::Concern
  include Folio::MediaFileProcessingBase

  def remote_content_url_base
    "https://#{ENV.fetch("CRA_MEDIA_CLOUD_CDN_CONTENT_URL")}.ssl.cdn.cra.cz"
  end

  def remote_manifest_url_base
    "https://#{ENV.fetch("CRA_MEDIA_CLOUD_CDN_MANIFEST_URL")}.ssl.cdn.cra.cz"
  end

  def remote_manifest_hls_url
    remote_manifest_url_base + remote_services_data["manifest_hls_path"]
  end

  def remote_manifest_dash_url
    remote_manifest_url_base + remote_services_data["manifest_dash_path"]
  end

  def remote_cover_url
    remote_content_url_base + remote_services_data["cover_path"]
  end

  def remote_thumbnails_url
    remote_content_url_base + remote_services_data["thumbnails_path"]
  end

  def remote_id
    remote_services_data["remote_id"]
  end

  def remote_reference_id
    remote_services_data["reference_id"]
  end

  def update_preview_media_length
    nil
  end

  def full_media_job_class
    Folio::CraMediaCloud::CreateMediaJob
  end

  def delete_media_job_class
    Folio::CraMediaCloud::DeleteMediaJob
  end

  def check_media_processing_job_class
    Folio::CraMediaCloud::CheckProgressJob
  end

  def processed_by
    "cra_media_cloud"
  end
end

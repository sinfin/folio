# frozen_string_literal: true

module Folio::CraMediaCloud::FileProcessing
  extend ActiveSupport::Concern
  include Folio::MediaFileProcessingBase

  def encoder_profile_group
    nil # use encoder's default
  end

  def remote_content_url_base
    ENV.fetch("CRA_MEDIA_CLOUD_CDN_CONTENT_URL")
  end

  def remote_manifest_url_base
    ENV.fetch("CRA_MEDIA_CLOUD_CDN_MANIFEST_URL")
  end

  def remote_manifest_hls_url
    if remote_services_data["manifest_hls_path"]
      remote_manifest_url_base + remote_services_data["manifest_hls_path"]
    end
  end

  def remote_manifest_dash_url
    if remote_services_data["manifest_dash_path"]
      remote_manifest_url_base + remote_services_data["manifest_dash_path"]
    end
  end

  def remote_cover_url
    if remote_services_data["cover_path"]
      remote_content_url_base + remote_services_data["cover_path"]
    end
  end

  def remote_thumbnails_url
    if remote_services_data["thumbnails_path"]
      remote_content_url_base + remote_services_data["thumbnails_path"]
    end
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

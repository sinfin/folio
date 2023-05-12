# frozen_string_literal: true

module Folio::JwPlayer::FileProcessing
  extend ActiveSupport::Concern

  PROCESSING_STATES = %w[enqueued
                         full_media_processing
                         full_media_processed
                         preview_media_processing
                         preview_media_processed]
  included do
    missing_envs ||= ENV.fetch("JWPLAYER_API_KEY").to_s.gsub("find-me-in-vault", "").blank?
    missing_envs ||= ENV.fetch("JWPLAYER_API_V1_SECRET").to_s.gsub("find-me-in-vault", "").blank?
    missing_envs ||= ENV.fetch("JWPLAYER_API_V2_SECRET").to_s.gsub("find-me-in-vault", "").blank?

    if missing_envs
      raise 'requires filled ENV["JWPLAYER_API_KEY"], ENV["JWPLAYER_API_V1_SECRET"] and ENV["JWPLAYER_API_V2_SECRET"]'
    end

    require "jwt"
  end

  def process_attached_file
    regenerate_thumbnails if try(:thumbnailable?)
    create_full_media # ensure call processing_done! after all processing is complete
  end

  def destroy_attached_file
    Folio::JwPlayer::DeleteMediaJob.perform_later(self.remote_key) if self.remote_key
    Folio::JwPlayer::DeleteMediaJob.perform_later(self.remote_preview_key) if self.remote_preview_key
  end

  def remote_key
    remote_services_data["remote_key"]
  end

  def remote_preview_key
    remote_services_data["remote_preview_key"]
  end

  def remote_path
    "/v2/media/#{remote_key}"
  end

  def remote_full_url
    "https://cdn.jwplayer.com#{remote_path}"
  end

  # player needs to send headers `{ "alg": "HS256",  "typ": "JWT"}`
  def remote_signed_full_url(expires_at = 2.hours.from_now)
    params = {
      "resource" => remote_path,
      "exp" => expires_at.to_i
    }

    token = JWT.encode(params, ENV.fetch("JWPLAYER_API_V1_SECRET"), "HS256", typ: "JWT")

    "#{remote_full_url}?token=#{token}"
  end

  def remote_preview_url
    "https://cdn.jwplayer.com/v2/media/#{remote_preview_key}"
  end

  def processing_state
    remote_services_data["processing_state"]
  end

  def processing_service
    remote_services_data["service"]
  end

  def full_media_processed!
    remote_services_data["processing_state"] = "full_media_processed"
    save!
    create_preview_media
  end

  def preview_media_processed!
    remote_services_data["processing_state"] = "preview_media_processed"
    processing_done!
  end

  def full_media_processed?
    PROCESSING_STATES.index("full_media_processed") <= PROCESSING_STATES.index(processing_state).to_i
  end

  def preview_media_processed?
    PROCESSING_STATES.index("preview_media_processed") <= PROCESSING_STATES.index(processing_state).to_i
  end

  def create_full_media
    Folio::JwPlayer::CreateFullMediaJob.perform_later(self)
    rsd = remote_services_data || {}
    self.remote_services_data = rsd.merge!({ "service" => "jw_player", "processing_state" => "enqueued" })
  end

  def create_preview_media
    Folio::JwPlayer::CreatePreviewMediaJob.perform_later(self)
  end

  def preview_starts_at_second
    preview_inteval["start_at"]
  end

  def preview_ends_at_second
    preview_inteval["end_at"]
  end

  def preview_inteval
    (remote_services_data || {}).dig("preview_interval") || { "start_at" => 0, "end_at" => preview_duration_in_seconds }
  end

  def duration_in_seconds
    (remote_services_data || {}).dig("full", "duration").to_i
  end

  def preview_duration_in_seconds
    if (remote_services_data || {}).dig("preview_interval").present?
      preview_ends_at_second - preview_starts_at_second
    else
      pd = (duration_in_seconds * 0.3).to_i # 30% of full media
      (pd < 2) ? 2 : pd
    end
  end

  def default_jw_player_tags
    [
      "folio",
      "folio-env-#{Rails.env}",
      self.class.to_s,
    ]
  end

  def jw_player_tags
    default_jw_player_tags
  end
end

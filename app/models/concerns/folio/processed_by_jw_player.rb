# frozen_string_literal: true

module Folio::ProcessedByJwPlayer
  extend ActiveSupport::Concern

  PROCESSING_STATES = %w[enqueued
                         full_media_processing
                         full_media_processed
                         preview_media_processing
                         preview_media_processed]
  included do
    missing_envs = ENV.fetch("JWPLAYER_API_KEY").to_s.gsub("find-me-in-vault", "").blank?
    missing_envs ||= ENV.fetch("JWPLAYER_API_SECRET").to_s.gsub("find-me-in-vault", "").blank?
    if missing_envs
      raise 'requires filled ENV["JWPLAYER_API_KEY"] and ENV["JWPLAYER_API_SECRET"]'
    end

    require "jwt"
  end

  def process_attached_file
    regenerate_thumbnails if try(:thumbnailable?)
    create_full_media # ensure call processing_done! after all processing is complete
  end

  def destroy_attached_file
    Folio::Files::JwPlayer::DeleteMediaJob.perform_later(self)
  end

  def remote_key
    remote_services_data["remote_key"]
  end

  def remote_preview_key
    remote_services_data["remote_preview_key"]
  end

  def remote_full_url
    "https://cdn.jwplayer.com/v2/media/#{remote_key}"
  end

  # player needs to send headers `{ "alg": "HS256",  "typ": "JWT"}`
  def remote_signed_full_url(expires_at = 2.hours.from_now)
    params = {
      "resource" => remote_full_url,
      "exp" => expires_at.to_i
    }

    token = JWT.encode(params, ENV.fetch("JWPLAYER_API_SECRET"), "HS256")

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
    Folio::Files::JwPlayer::CreateFullMediaJob.perform_later(self)
    rsd = remote_services_data || {}
    self.remote_services_data = rsd.merge!({ "service" => "jw_player", "processing_state" => "enqueued" })
  end

  def create_preview_media
    Folio::Files::JwPlayer::CreatePreviewMediaJob.perform_later(self)
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
    (remote_services_data || {}).dig("metadata", "duration").to_i
  end

  def preview_duration_in_seconds
    if (remote_services_data || {}).dig("preview_interval").present?
      preview_ends_at_second - preview_starts_at_second
    else
      pd = (duration_in_seconds * 0.3).to_i
      (pd < 2) ? 2 : pd
    end
  end
end

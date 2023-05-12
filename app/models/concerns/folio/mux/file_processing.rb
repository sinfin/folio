# frozen_string_literal: true

module Folio::Mux::FileProcessing
  extend ActiveSupport::Concern

  PROCESSING_STATES = %w[enqueued
                         full_media_processing
                         full_media_processed
                         preview_media_processing
                         preview_media_processed]
  included do
    missing_envs = ENV.fetch("MUX_API_KEY").to_s.gsub("find-me-in-vault", "").blank?
    missing_envs ||= ENV.fetch("MUX_API_SECRET").to_s.gsub("find-me-in-vault", "").blank?
    missing_envs ||= ENV.fetch("MUX_SIGNING_KEY").to_s.gsub("find-me-in-vault", "").blank?
    missing_envs ||= ENV.fetch("MUX_SIGNING_PRIVATE_KEY").to_s.gsub("find-me-in-vault", "").blank?

    if missing_envs
      raise 'requires filled ENVs :"MUX_API_KEY", "MUX_API_SECRET", "MUX_SIGNING_KEY", "MUX_SIGNING_PRIVATE_KEY"'
    end

    require "jwt"
  end

  def process_attached_file
    regenerate_thumbnails if try(:thumbnailable?)
    create_full_media # ensure call processing_done! after all processing is complete
  end

  def destroy_attached_file
    Folio::Mux::DeleteMediaJob.perform_later(self.remote_key)
    Folio::Mux::DeleteMediaJob.perform_later(self.remote_preview_key)
  end

  def remote_key
    remote_services_data["remote_key"]
  end

  def remote_preview_key
    remote_services_data["remote_preview_key"]
  end

  def remote_full_url
    "https://stream.mux.com/#{public_full_playback_id}"
  end

  # player needs to send headers `{ "alg": "HS256",  "typ": "JWT"}`
  def remote_signed_full_url(expires_at = 2.hours.from_now)
    params = {
      sub: signed_full_playback_id,
      aud: "v",	# Audience (intended application of the token):	v => (Video or Subtitles/Closed Captions)
      exp: expires_at.to_i,
      kid: ENV.fetch("MUX_SIGNING_KEY")
    }

    rsa_private = OpenSSL::PKey::RSA.new(Base64.decode64(ENV.fetch("MUX_SIGNING_PRIVATE_KEY")))

    token = JWT.encode(params, rsa_private, "RS256")

    "https://stream.mux.com/#{signed_full_playback_id}.m3u8?token=#{token}"
  end

  def remote_preview_url
    playback_id = remote_services_data["preview"]["playback_ids"].first["id"]
    "https://stream.mux.com/#{playback_id}.m3u8"
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
    Folio::Mux::CreateFullMediaJob.perform_later(self)
    rsd = remote_services_data || {}
    self.remote_services_data = rsd.merge!({ "service" => "mux", "processing_state" => "enqueued" })
  end

  def create_preview_media
    Folio::Mux::CreatePreviewMediaJob.perform_later(self)
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
      pd = (duration_in_seconds * 0.3).to_i
      (pd < 2) ? 2 : pd
    end
  end

  def signed_full_playback_id
    remote_services_data["full"]["playback_ids"].detect { |pb| pb["policy"] == "signed" }["id"]
  end

  def public_full_playback_id
    remote_services_data["full"]["playback_ids"].detect { |pb| pb["policy"] == "public" }["id"]
  end
end

# frozen_string_literal: true

module Folio::Mux::FileProcessing
  extend ActiveSupport::Concern
  include Folio::MediaFileProcessingBase

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

  def remote_full_url
    "https://stream.mux.com/#{public_full_playback_id}"
  end

  # player needs to send headers `{ "alg": "HS256",  "typ": "JWT"}`
  def remote_signed_full_url(expires_at = 2.hours.from_now)
    if Rails.env.test?
      token = "test"
    else
      params = {
        sub: signed_full_playback_id,
        aud: "v",	# Audience (intended application of the token):	v => (Video or Subtitles/Closed Captions)
        exp: expires_at.to_i,
        kid: ENV.fetch("MUX_SIGNING_KEY")
      }

      rsa_private = OpenSSL::PKey::RSA.new(Base64.decode64(ENV.fetch("MUX_SIGNING_PRIVATE_KEY")))

      token = JWT.encode(params, rsa_private, "RS256")
    end

    "https://stream.mux.com/#{signed_full_playback_id}.m3u8?token=#{token}"
  end

  def remote_preview_url
    playback_id = remote_services_data["preview"]["playback_ids"].first["id"]
    "https://stream.mux.com/#{playback_id}.m3u8"
  end

  def remote_signed_preview_url(_expires_at)
    remote_preview_url
  end

  def full_media_job_class
    Folio::Mux::CreateFullMediaJob
  end

  def preview_media_job_class
    Folio::Mux::CreatePreviewMediaJob
  end

  def delete_media_job_class
    Folio::Mux::DeleteMediaJob
  end

  def check_media_processing_job_class
    Folio::Mux::CheckProgressJob
  end

  def signed_full_playback_id
    pb = full_playbacks.detect { |pb| pb["policy"] == "signed" }
    pb && pb["id"]
  end

  def public_full_playback_id
    pb = full_playbacks.detect { |pb| pb["policy"] == "public" }
    pb && pb["id"]
  end

  def full_playbacks
    remote_services_data.dig("full", "playback_ids") || []
  end

  def processed_by
    "mux"
  end
end

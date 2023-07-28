# frozen_string_literal: true

module Folio::JwPlayer::FileProcessing
  extend ActiveSupport::Concern
  include Folio::MediaFileProcessingBase

  included do
    missing_envs ||= ENV.fetch("JWPLAYER_API_KEY").to_s.gsub("find-me-in-vault", "").blank?
    missing_envs ||= ENV.fetch("JWPLAYER_API_V1_SECRET").to_s.gsub("find-me-in-vault", "").blank?
    missing_envs ||= ENV.fetch("JWPLAYER_API_V2_SECRET").to_s.gsub("find-me-in-vault", "").blank?

    if missing_envs
      raise 'requires filled ENV["JWPLAYER_API_KEY"], ENV["JWPLAYER_API_V1_SECRET"] and ENV["JWPLAYER_API_V2_SECRET"]'
    end

    require "jwt"
  end

  def remote_path(key)
    "/v2/media/#{key}"
  end

  def remote_url_base
    "https://cdn.jwplayer.com"
  end

  def remote_full_url
    remote_url_base + remote_path(remote_key)
  end

  def remote_preview_url
    remote_url_base + remote_path(remote_preview_key)
  end

  def remote_signed_full_url(expires_at = 2.hours.from_now)
    token = token_for_remote_signed_url(remote_path(remote_key), expires_at)
    "#{remote_full_url}?token=#{token}"
  end

  def remote_signed_preview_url(expires_at = 2.hours.from_now)
    token = token_for_remote_signed_url(remote_path(remote_preview_key), expires_at)
    "#{remote_preview_url}?token=#{token}"
  end

  # player needs to send headers `{ "alg": "HS256",  "typ": "JWT"}`
  def token_for_remote_signed_url(remote_path, expires_at)
    params = {
      "resource" => remote_path,
      "exp" => expires_at.to_i
    }

    if Rails.env.test?
      "test"
    else
      JWT.encode(params, ENV.fetch("JWPLAYER_API_V1_SECRET"), "HS256", typ: "JWT")
    end
  end

  def full_media_job_class
    Folio::JwPlayer::CreateFullMediaJob
  end

  def preview_media_job_class
    Folio::JwPlayer::CreatePreviewMediaJob
  end

  def delete_media_job_class
    Folio::JwPlayer::DeleteMediaJob
  end

  def check_media_processing_job_class
    Folio::JwPlayer::CheckProgressJob
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

  def processed_by
    "jw_player"
  end
end

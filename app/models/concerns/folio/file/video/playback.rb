# frozen_string_literal: true

module Folio::File::Video::Playback
  extend ActiveSupport::Concern

  def video_playback_provider_key
    remote_services_data["service"].presence ||
      (respond_to?(:processed_by) ? processed_by.to_s : default_video_playback_provider_key)
  end

  def video_playback_provider
    key = video_playback_provider_key
    if @video_playback_provider.blank? || @video_playback_provider_key != key
      @video_playback_provider_key = key
      @video_playback_provider = video_playback_provider_class_for(key).new(self)
    end

    @video_playback_provider
  end

  def video_playback_ready?
    video_playback_provider.ready?
  end

  def video_playback_sources
    video_playback_provider.sources
  end

  def video_playback_embed_url
    video_playback_provider.embed_url
  end

  def video_playback_poster_url
    video_playback_provider.poster_url
  end

  def video_processing_state
    video_playback_provider.processing_state
  end

  def video_processing_error_message
    video_playback_provider.error_message
  end

  def video_seo_metadata
    video_playback_provider.seo_metadata
  end

  private
    def default_video_playback_provider_key
      Rails.application.config.folio_files_video_default_processing_provider.to_s
    end

    def video_playback_provider_class_for(key)
      class_name = Rails.application.config.folio_files_video_playback_provider_classes[key.to_s]
      unless class_name
        raise Folio::Video::Providers::UnknownProviderError,
              "Unknown video playback provider '#{key}'. Configure " \
              "`config.folio_files_video_playback_provider_classes` or use `direct_file`."
      end

      klass = class_name.safe_constantize
      return klass if klass

      raise Folio::Video::Providers::UnavailableProviderError,
            "Video playback provider '#{key}' is configured as `#{class_name}`, " \
            "but that constant is unavailable. Enable the matching Folio pack " \
            "in `Folio.enabled_packs` or change `config.folio_files_video_default_processing_provider`."
    end
end

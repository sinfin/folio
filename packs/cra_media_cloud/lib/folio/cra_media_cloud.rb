# frozen_string_literal: true

module Folio::CraMediaCloud
  PROVIDER_KEY = "cra_media_cloud"
  VIDEO_PROVIDER_CLASS_NAME = "Folio::CraMediaCloud::VideoProvider"

  class << self
    def register_video_provider!
      config = Rails.application.config

      config.folio_files_video_playback_provider_classes =
        config.folio_files_video_playback_provider_classes.merge(PROVIDER_KEY => VIDEO_PROVIDER_CLASS_NAME)
    end
  end
end

Folio::CraMediaCloud.register_video_provider! if defined?(Rails)

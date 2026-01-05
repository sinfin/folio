# frozen_string_literal: true

class Folio::Console::Files::IndexModalComponent < Folio::Console::ApplicationComponent
  CLASS_NAME = "f-c-files-index-modal"

  def initialize
  end

  def data
    stimulus_controller(CLASS_NAME,
                        values: { turbo_frame_config: },
                        action: {
                          "f-c-files-index-modal:openWithType" => "openWithType",
                          "f-file-list-file:select" => "onFileSelect",
                          "f-modal:closed" => "onModalClosed",
                        })
  end

  def turbo_frame_config
    h = {}

    Rails.application.config.folio_file_types_for_routes.each do |type|
      klass = type.constantize
      h[type] = {
        src: url_for([:console, klass]),
        id: klass.console_turbo_frame_id(modal: true),
      }
    end

    h
  end

  def file_klasses
    Rails.application.config.folio_file_types_for_routes.map(&:constantize)
  end
end

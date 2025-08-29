# frozen_string_literal: true

class Folio::Console::Files::IndexModalComponent < Folio::Console::ApplicationComponent
  CLASS_NAME = "f-c-files-index-modal"

  def initialize
  end

  def data
    stimulus_controller(CLASS_NAME,
                        values: {
                          turbo_frame_urls:,
                          turbo_frame_id: Folio::Console::FileControllerBase::TURBO_FRAME_ID,
                        },
                        action: {
                          "f-c-files-index-modal:openWithType" => "openWithType",
                        })
  end

  def turbo_frame_urls
    h = {}

    Rails.application.config.folio_file_types_for_routes.each do |type|
      h[type] = url_for([:console, type.constantize])
    end

    h.to_json
  end
end

# frozen_string_literal: true

class Folio::Console::Files::Index::ModalComponent < Folio::Console::ApplicationComponent
  CLASS_NAME = "f-c-files-index-modal"

  def initialize(file_type:)
    @klass = file_type.constantize
    raise "Unexpected class: #{file_type}" unless @klass < Folio::File
  end

  def title
    t(".title/#{@klass.human_type}", default: t(".title"))
  end

  def data
    stimulus_controller(CLASS_NAME,
                        values: {
                          file_type: @klass.name,
                          base_api_url: url_for([:console, :api, @klass]),
                          status: "loading",
                        },
                        action: {
                          "f-c-files-picker:open" => "onPickerOpen",
                          "f-modal:opened" => "onModalOpened",
                          "f-modal:closed" => "onModalClosed",
                        })
  end
end

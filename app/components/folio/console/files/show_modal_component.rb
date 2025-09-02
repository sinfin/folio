# frozen_string_literal: true

class Folio::Console::Files::ShowModalComponent < ApplicationComponent
  CLASS_NAME = "f-c-files-show-modal"

  def initialize(file: nil)
    @file = file
  end

  private
    def data
      stimulus_controller("f-c-files-show-modal",
                          values: { id: @file&.id.to_s },
                          action: {
                            "f-c-files-show-modal:openWithUrl" => "openWithUrl",
                            "f-c-files-show:deleted" => "onFileDeleted",
                            "f-modal:closed" => "onModalClosed",
                          })
    end
end

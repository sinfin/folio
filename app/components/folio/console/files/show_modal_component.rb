# frozen_string_literal: true

class Folio::Console::Files::ShowModalComponent < ApplicationComponent
  CLASS_NAME = "f-c-files-show-modal"

  def initialize(file: nil)
    @file = file
  end

  def data
    stimulus_controller("f-c-files-show-modal",
                        values: {
                          id: @file.try(:id),
                          loading: @file.blank?,
                        },
                        action: {
                          "f-c-files-show-modal/show-file" => "showFile",
                          "f-c-files-show:deleted" => "onFileDeleted",
                        })
  end
end

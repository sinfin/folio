# frozen_string_literal: true

class Folio::SpecialCharacters::PopupComponent < Folio::ApplicationComponent
  def initialize; end

  private
    def data
      stimulus_controller("f-special-characters-popup",
                          action: {
                            "f-special-characters-trigger:toggle@document" => "toggle",
                            mousedown: "preventDefault",
                          })
    end

    def header_data
      stimulus_action(mousedown: "onDragHandleMousedown",
                      touchstart: "onDragHandleTouchstart")
    end
end

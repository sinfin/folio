# frozen_string_literal: true

class Folio::SpecialCharacters::TriggerComponent < Folio::ApplicationComponent
  def initialize; end

  private
    def data
      stimulus_controller("f-special-characters-trigger").merge(test_id: "special-characters-trigger")
    end

    def mobile_button_data
      stimulus_action(mousedown: "preventDefault",
                      click: "toggleFromMobile")
    end

    def desktop_button_data
      stimulus_action(mousedown: "preventDefault",
                      click: "toggleFromDesktop")
    end
end

# frozen_string_literal: true

class Folio::SpecialCharacters::TriggerComponent < Folio::ApplicationComponent
  def initialize; end

  private
    def data
      stimulus_controller("f-special-characters-trigger").merge(test_id: "special-characters-trigger")
    end

    def button_data
      stimulus_action(click: "toggle")
    end
end

# frozen_string_literal: true

class Folio::SpecialCharacters::TriggerComponent < Folio::SpecialCharacters::ApplicationComponent
  def button_data
    stimulus_merge_data(
      stimulus_data(controller: "f-special-characters-popup", action: { click: "toggle" }),
      { test_id: "special-characters-trigger" },
    )
  end
end

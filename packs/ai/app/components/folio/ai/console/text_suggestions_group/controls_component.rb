# frozen_string_literal: true

class Folio::Ai::Console::TextSuggestionsGroup::ControlsComponent < Folio::Console::ApplicationComponent
  def initialize
  end

  private
    def component_data
      stimulus_controller("f-ai-c-text-suggestions-group-controls",
                          action: {
                            "f-ai-c-text-suggestions-group:state": "onGroupState",
                          })
    end

    def button_data
      stimulus_data(action: { click: "generate" },
                    target: "button")
    end

    def close_data
      stimulus_data(action: { click: "close" },
                    target: "close")
    end

    def generate_all_label
      label(:generate_all_label)
    end

    def close_label
      label(:close_all_label)
    end

    def label(key)
      I18n.t(key, scope: "folio.ai.console.text_suggestions_group_component")
    end
end

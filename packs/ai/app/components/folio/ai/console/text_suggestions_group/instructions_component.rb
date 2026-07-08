# frozen_string_literal: true

class Folio::Ai::Console::TextSuggestionsGroup::InstructionsComponent < Folio::Console::ApplicationComponent
  def initialize(stored_instruction:)
    @stored_instruction = stored_instruction
  end

  private
    def component_data
      stimulus_controller("f-ai-c-text-suggestions-group-instructions",
                          action: {
                            "f-ai-c-text-suggestions-group:state": "onGroupState",
                          })
    end

    def instructions_data
      stimulus_merge(stimulus_controller("f-input-autosize", inline: true),
                     stimulus_target("instructions"))
    end

    def regenerate_data
      stimulus_data(action: { click: "regenerate" },
                    target: "regenerate")
    end

    def instructions_placeholder
      label(:instructions_placeholder)
    end

    def regenerate_label
      label(:regenerate_all_label)
    end

    def label(key)
      I18n.t(key, scope: "folio.ai.console.text_suggestions_group_component")
    end
end

# frozen_string_literal: true

class Folio::Ai::Console::TextSuggestions::ActionsComponent < Folio::Console::ApplicationComponent
  BEM_CLASS_NAME = Folio::Ai::Console::TextSuggestionsComponent::BEM_CLASS_NAME
  CONTROLLER_NAME = "f-ai-c-text-suggestions-actions"

  def self.button_id(component_id)
    "#{component_id}_button"
  end

  def self.undo_id(component_id)
    "#{component_id}_undo"
  end

  def initialize(component_id:, button_label: nil, external: false)
    @component_id = component_id
    @button_label = button_label
    @external = external
  end

  private
    def original_bem_class_name
      BEM_CLASS_NAME
    end

    def data
      stimulus_controller(CONTROLLER_NAME,
                          values: { component_id: @component_id },
                          action: {
                            "f-ai-c-text-suggestions:state@document": "onState",
                          },
                          classes: %w[loading])
    end

    def wrapper_classes
      [
        (BEM_CLASS_NAME if external?),
        "#{BEM_CLASS_NAME}__actions",
        ("#{BEM_CLASS_NAME}--external-actions" if external?),
      ].compact
    end

    def button_id
      self.class.button_id(@component_id)
    end

    def undo_id
      self.class.undo_id(@component_id)
    end

    def button_label
      @button_label.presence ||
        I18n.t("folio.ai.console.text_suggestions_component.button_label")
    end

    def undo_label
      I18n.t("folio.ai.console.text_suggestions_component.undo_label")
    end

    def sparkles_icon
      Folio::Ai::Icons.sparkles(self)
    end

    def undo_icon
      Folio::Ai::Icons.undo(self)
    end

    def external?
      @external
    end
end

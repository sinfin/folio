# frozen_string_literal: true

# Renders the AI input button, undo button, and suggestion mount point.
class Folio::Ai::Console::InputControlsComponent < Folio::Console::ApplicationComponent
  def initialize(component_id:, label:, undo_label: nil)
    @component_id = component_id
    @label = label
    @undo_label = undo_label || I18n.t("folio.ai.input.undo")
  end

  private
    def button_id
      "#{@component_id}_button"
    end

    def undo_id
      "#{@component_id}_undo"
    end

    def button_data
      stimulus_data(action: { click: "toggle" },
                    target: "button")
    end

    def undo_data
      stimulus_data(action: { click: "undo" },
                    target: "undo")
    end

    def custom_html_data
      stimulus_data(target: "customHtml")
    end
end

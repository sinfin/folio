# frozen_string_literal: true

# Renders the AI input button, undo button, and suggestion mount point.
class Folio::Ai::Console::InputControlsComponent < Folio::Console::ApplicationComponent
  def initialize(component_id:, label:, undo_label: nil, show_button: true)
    @component_id = component_id
    @label = label
    @undo_label = undo_label || I18n.t("folio.ai.input.undo")
    @show_button = show_button
  end

  private
    def show_button?
      @show_button
    end

    def button_id
      "#{@component_id}_button"
    end

    def undo_id
      "#{@component_id}_undo"
    end
end

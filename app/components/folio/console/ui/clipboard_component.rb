# frozen_string_literal: true

class Folio::Console::Ui::ClipboardComponent < Folio::Console::ApplicationComponent
  def initialize(text:,
                 class_name: nil,
                 as_button: false,
                 button_label: nil,
                 button_variant: nil,
                 icon: nil,
                 icon_height: nil,
                 label: nil)
    @text = text
    @class_name = class_name
    @as_button = as_button
    @button_label = button_label
    @button_variant = button_variant
    @icon = icon
    @icon_height = icon_height
    @label = label
  end

  private
    def data
      stimulus_controller("f-c-ui-clipboard",
                          classes: %w[copied]).merge("clipboard-text" => @text)
    end
end

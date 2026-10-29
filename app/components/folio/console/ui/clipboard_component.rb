# frozen_string_literal: true

class Folio::Console::Ui::ClipboardComponent < Folio::Console::ApplicationComponent
  def initialize(text:,
                 class_name: nil,
                 as_button: false,
                 as_icon: false,
                 button_label: nil,
                 button_variant: nil,
                 icon: nil,
                 icon_height: nil,
                 label: nil)
    @text = text
    @class_name = class_name
    @as_button = as_button
    @as_icon = as_icon
    @button_label = button_label
    @button_variant = button_variant
    @icon = icon
    @icon_height = icon_height
    @label = label
  end

  private
    def icon_tag
      tag = {
        tag: @as_icon ? :button : :span,
        class: "f-c-ui-clipboard__span f-c-ui-clipboard__span--height-#{@icon_height || 16}",
      }

      if @as_icon
        tag.merge!(type: :button,
                   class: "#{tag[:class]} f-c-ui-clipboard__button",
                   title: @label || t(".copy"),
                   "aria-label" => @label || t(".copy"))
      end

      tag
    end

    def data
      stimulus_controller("f-c-ui-clipboard",
                          classes: %w[copied]).merge("clipboard-text" => @text)
    end
end

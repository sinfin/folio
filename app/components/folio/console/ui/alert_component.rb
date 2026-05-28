# frozen_string_literal: true

class Folio::Console::Ui::AlertComponent < Folio::Console::ApplicationComponent
  bem_class_name :flash

  def initialize(variant: :info, closable: true, class_name: nil, flash: false, icon: nil, autohide: false)
    @variant = variant
    @closable = closable
    @class_name = class_name
    @flash = flash
    @icon = icon
    @autohide = autohide
  end

  def data
    stimulus_controller("f-c-ui-alert", values: { autohide: @autohide })
  end

  def icon_key
    return @icon if @icon

    case @variant
    when :success
      :check_circle_outline
    when :warning, :danger
      :alert
    else
      :information_outline
    end
  end
end

# frozen_string_literal: true

class Folio::Console::Ui::AlertComponent < Folio::Console::ApplicationComponent
  bem_class_name :flash

  def initialize(variant: :info, closable: true, class_name: nil, flash: false, icon: nil, autohide: false, stimulus_controllers: [], data: {})
    @variant = variant
    @closable = closable
    @class_name = class_name
    @flash = flash
    @icon = icon
    @autohide = autohide
    @stimulus_controllers = Array.wrap(stimulus_controllers).compact_blank
    @extra_data = (data || {}).transform_keys(&:to_s)
  end

  def data
    base = stimulus_controller("f-c-ui-alert", values: { autohide: @autohide })

    if @stimulus_controllers.any?
      base["controller"] = (["f-c-ui-alert"] + @stimulus_controllers).uniq.join(" ")
    end

    base.merge(@extra_data)
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

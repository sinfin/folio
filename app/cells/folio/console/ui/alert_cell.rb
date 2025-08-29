# frozen_string_literal: true

class Folio::Console::Ui::AlertCell < Folio::ConsoleCell
  class_name "f-c-ui-alert", :flash

  def variant
    options[:variant] || :info
  end

  def icon_key
    return options[:icon] if options[:icon]

    case variant
    when :success
      :check_circle_outline
    when :warning, :danger
      :alert
    else
      :information_outline
    end
  end

  def data
    stimulus_controller("f-c-ui-alert", values: {
      autohide: options[:autohide] ? true : nil
    }.compact)
  end
end

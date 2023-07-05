# frozen_string_literal: true

class Folio::Console::Ui::AlertCell < Folio::ConsoleCell
  class_name "f-c-ui-alert", :flash

  def variant
    options[:variant] || :info
  end

  def icon_key
    case variant
    when :success
      :check_circle_outline
    when :warning, :danger
      :alert
    else
      :information_outline
    end
  end
end

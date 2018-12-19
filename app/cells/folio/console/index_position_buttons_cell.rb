# frozen_string_literal: true

class Folio::Console::IndexPositionButtonsCell < Folio::ConsoleCell
  def url
    options[:url] || guessed_url
  end

  def as
    options[:as] || model.class.table_name
  end

  def guessed_url
    path = "set_positions_console_#{as}"

    if Folio::Engine.routes.routes.map(&:name).include?(path)
      controller.send("#{path}_path")
    else
      controller.main_app.public_send("#{path}_path")
    end
  end
end

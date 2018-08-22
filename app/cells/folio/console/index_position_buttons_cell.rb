# frozen_string_literal: true

class Folio::Console::IndexPositionButtonsCell < FolioCell
  def url
    options[:url] || guessed_url
  end

  def as
    options[:as] || model.class.table_name
  end

  def guessed_url
    path = "set_positions_console_#{as}_path"

    if Folio::Engine.routes.routes.map(&:name).include?(path)
      controller.send(path)
    else
      controller.main_app.public_send(path)
    end
  end
end

# frozen_string_literal: true

class Folio::Console::Ui::StiBadgeCell < Folio::ConsoleCell
  def icon
    if model.class.respond_to?(:klasses_for_console)
      model.class.klasses_for_console[model.class]
    end
  end
end

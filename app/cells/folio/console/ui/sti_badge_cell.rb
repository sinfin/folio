# frozen_string_literal: true

class Folio::Console::Ui::StiBadgeCell < Folio::ConsoleCell
  def icon
    if model_class.respond_to?(:klasses_for_console)
      model_class.klasses_for_console[model_class]
    end
  end

  def model_class
    @model_class ||= if model.new_record? && model.type
      model.type.constantize
    else
      model.class
    end
  end
end

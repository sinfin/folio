# frozen_string_literal: true

class Folio::Console::Form::HeaderCell < Folio::ConsoleCell
  def record
    model.try(:object) || model
  end

  def translations
    cell('folio/console/pages/translations', model, as_pills: true)
  end
end

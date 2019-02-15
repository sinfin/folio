# frozen_string_literal: true

class Folio::Console::Form::HeaderCell < Folio::ConsoleCell
  def translations
    cell('folio/console/pages/translations', model, as_pills: true)
  end
end

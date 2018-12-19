# frozen_string_literal: true

class Folio::Console::Form::HeaderCell < Folio::ConsoleCell
  def translations
    cell('folio/console/nodes/translations', model.original, as_pills: true)
  end
end

# frozen_string_literal: true

class Folio::Console::Form::HeaderCell < Folio::ConsoleCell
  def record
    model.try(:object) || model
  end

  def translations
    cell("folio/console/pages/translations", record, as_pills: true)
  end

  def soft_warnings
    return [] unless record&.respond_to?(:soft_warnings_for_file_placements)

    record.soft_warnings_for_file_placements
  end
end

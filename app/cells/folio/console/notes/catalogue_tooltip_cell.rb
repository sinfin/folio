# frozen_string_literal: true

class Folio::Console::Notes::CatalogueTooltipCell < Folio::ConsoleCell
  def show
    render if model && model.console_notes.present? && model.console_notes.any? { |note| !note.closed_at? }
  end
end

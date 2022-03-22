# frozen_string_literal: true

class Folio::Console::ConsoleNotes::CatalogueTooltipCell < Folio::ConsoleCell
  class_name "f-c-console-notes-catalogue-tooltip", :some_open?, :only_closed?

  def show
    render if model && model.console_notes.present?
  end

  def some_open?
    return @some_open unless @some_open.nil?
    @some_open = model.console_notes.present? && model.console_notes.any? { |note| !note.closed_at? }
  end

  def only_closed?
    !some_open?
  end
end

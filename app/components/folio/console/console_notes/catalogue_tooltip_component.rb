# frozen_string_literal: true

class Folio::Console::ConsoleNotes::CatalogueTooltipComponent < Folio::Console::ApplicationComponent
  def initialize(record:)
    @record = record
  end

  def render?
    @record && @record.console_notes.present?
  end

  def some_open?
    return @some_open unless @some_open.nil?
    @some_open = @record.console_notes.present? && @record.console_notes.any? { |note| !note.closed_at? }
  end

  def only_closed?
    !some_open?
  end

  def class_name
    classes = ["f-c-console-notes-catalogue-tooltip"]
    classes << "f-c-console-notes-catalogue-tooltip--some-open" if some_open?
    classes << "f-c-console-notes-catalogue-tooltip--only-closed" if only_closed?
    classes.join(" ")
  end
end

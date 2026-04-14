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

  def catalogue_tooltip_data
    stimulus_merge_data(
      stimulus_controller("f-c-console-notes-catalogue-tooltip",
                          action: { change: "onNoteChange" },
                          inline: true),
      tooltip_note_parent_data
    )
  end

  private
    def tooltip_note_parent_data
      {
        class_name_parent: Folio::Console::ReactHelper::REACT_NOTE_PARENT_CLASS_NAME,
        class_name_form_parent: Folio::Console::ReactHelper::REACT_NOTE_FORM_PARENT_CLASS_NAME,
      }
    end
end

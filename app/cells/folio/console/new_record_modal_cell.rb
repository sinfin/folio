# frozen_string_literal: true

class Folio::Console::NewRecordModalCell < Folio::ConsoleCell
  def toggle
    render(:toggle)
  end

  def modal_class_name
    "f-c-new-record-modal--#{model.table_name}"
  end
end

# frozen_string_literal: true

class Folio::Console::Index::CheckboxesCell < FolioCell
  def show
    render
  end

  def toggle
    render(:toggle)
  end
end

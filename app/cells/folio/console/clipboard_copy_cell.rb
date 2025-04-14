# frozen_string_literal: true

class Folio::Console::ClipboardCopyCell < Folio::ConsoleCell
  def show
    render if model.present?
  end
end

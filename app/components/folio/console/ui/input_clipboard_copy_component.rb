# frozen_string_literal: true

class Folio::Console::Ui::InputClipboardCopyComponent < Folio::Console::ApplicationComponent
  def initialize(string:)
    @string = string
  end
end

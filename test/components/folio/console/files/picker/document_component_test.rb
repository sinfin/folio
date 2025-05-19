# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::Picker::DocumentComponentTest < Folio::Console::ComponentTest
  def test_render
    file = create(:folio_file_document)

    render_inline(Folio::Console::Files::Picker::DocumentComponent.new(file:))

    assert_selector(".f-c-files-picker-document")
  end
end

# frozen_string_literal: true

require "test_helper"

class Folio::Console::SharePreviewModalComponentTest < Folio::Console::ComponentTest
  def test_render
    record = create(:folio_page)

    render_inline(Folio::Console::SharePreviewModalComponent.new(record:))

    assert_selector(".f-c-share-preview-modal")
  end
end

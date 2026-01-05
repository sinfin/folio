# frozen_string_literal: true

require "test_helper"

class Folio::FileList::TriggerComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Folio::FileList::TriggerComponent.new)
    assert_selector(".f-file-list-trigger")
  end
end

# frozen_string_literal: true

require "test_helper"

class Folio::FileList::LoaderComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Folio::FileList::LoaderComponent.new)
    assert_selector(".f-file-list-loader")
  end
end

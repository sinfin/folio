# frozen_string_literal: true

require "test_helper"

class Folio::FileList::FileComponentTest < Folio::ComponentTest
  def test_file
    file = create(:folio_file_image)

    render_inline(Folio::FileList::FileComponent.new(file:))

    assert_selector(".f-file-list-file")
    assert_selector(".f-file-list-file__image-wrap")
    assert_no_selector(".f-file-list-file__loader")
  end

  def test_template
    render_inline(Folio::FileList::FileComponent.new(file: nil, template: true))

    assert_selector(".f-file-list-file")
    assert_selector(".f-file-list-file__image-wrap")
    assert_selector(".f-file-list-file__loader")
  end
end

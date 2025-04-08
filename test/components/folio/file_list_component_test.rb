# frozen_string_literal: true

require "test_helper"

class Folio::FileListComponentTest < Folio::ComponentTest
  def test_blank
    render_inline(Folio::FileListComponent.new(file_klass: Folio::File::Image))
    assert_selector(".f-file-list")
    assert_selector(".f-file-list-file", count: 1)
    assert_selector(".f-file-list-file--thead", count: 1)
  end

  def test_with_files
    files = create_list(:folio_file_image, 2)

    render_inline(Folio::FileListComponent.new(file_klass: Folio::File::Image, files:))
    assert_selector(".f-file-list")
    assert_selector(".f-file-list-file", count: 3)
    assert_selector(".f-file-list-file--thead", count: 1)
  end
end

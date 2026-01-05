# frozen_string_literal: true

require "test_helper"

class Folio::FileList::File::BatchCheckboxComponentTest < Folio::ComponentTest
  def test_render
    file = create(:folio_file_image)

    render_inline(Folio::FileList::File::BatchCheckboxComponent.new(file:))

    assert_selector(".f-file-list-file-batch-checkbox")
  end
end

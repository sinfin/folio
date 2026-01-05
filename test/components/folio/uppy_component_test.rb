# frozen_string_literal: true

require "test_helper"

class Folio::UppyComponentTest < Folio::ComponentTest
  def test_render
    file_type = "Folio::File::Image"

    render_inline(Folio::UppyComponent.new(file_type:))

    assert_selector(".f-uppy")
  end
end

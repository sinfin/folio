# frozen_string_literal: true

require "test_helper"

class Folio::DropzoneComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Folio::DropzoneComponent.new(file_type: "Folio::PrivateAttachment",
                                               file_human_type: "document"))

    assert_selector(".f-dropzone")
  end
end

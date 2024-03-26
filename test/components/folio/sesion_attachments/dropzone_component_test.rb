# frozen_string_literal: true

require "test_helper"

class Folio::SesionAttachments::DropzoneComponentTest < Folio::ComponentTest
  def test_render
    klass = Folio::SessionAttachment::Base

    render_inline(Folio::SesionAttachments::DropzoneComponent.new(klass:))

    assert_selector(".f-sesion-attachments-dropzone")
  end
end

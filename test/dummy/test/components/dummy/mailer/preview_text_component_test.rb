# frozen_string_literal: true

require "test_helper"

class Dummy::Mailer::PreviewTextComponentTest < Folio::ComponentTest
  def test_render
    preview_text = "Some hidden preview text. Should be minimal 90 characters long. Lorem ipsum dolor sit amet, lorem ipsum"

    render_inline(Dummy::Mailer::PreviewTextComponent.new(text: preview_text))

    assert_selector(".d-mailer-preview-text")
  end
end

# frozen_string_literal: true

require "test_helper"

class Folio::Console::Form::HeaderComponentTest < Folio::Console::ComponentTest
  def test_render
    title = "Hello world!"
    page = create(:folio_page, title:)

    f = ActionView::Helpers::FormBuilder.new(:page, page, vc_test_controller.view_context, {})

    render_inline(Folio::Console::Form::HeaderComponent.new(f: f, title: page.title))

    assert_selector(".f-c-form-header")
    assert_text(title)
  end
end

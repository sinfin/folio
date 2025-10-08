# frozen_string_literal: true

require "test_helper"

class Folio::Console::Form::HeaderComponentTest < Folio::Console::ComponentTest
  def test_render
    title = "Hello world!"
    page = create(:folio_page, title:)

    render_inline(Folio::Console::Form::HeaderComponent.new(model: page, title: page.title))

    assert_selector(".f-c-form-header")
    assert_text(title)
  end
end

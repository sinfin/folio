# frozen_string_literal: true

require "test_helper"

class Folio::Console::Form::LayoutComponentTest < Folio::Console::ComponentTest
  def test_render
    render_inline(Folio::Console::Form::LayoutComponent.new) { "Content" }

    assert_selector(".f-c-form-layout")
    assert_selector(".f-c-form-layout__grid")
    assert_selector(".f-c-form-layout__grid-item.f-c-form-layout__grid-item--content",
                    text: "Content")
  end

  def test_render_with_file_pickers
    component = Folio::Console::Form::LayoutComponent.new
    component.with_file_pickers { "Picker" }

    render_inline(component) { "Content" }

    assert_selector(".f-c-form-layout__grid-item.f-c-form-layout__grid-item--file-pickers")
    assert_selector(".f-c-form-layout__file-pickers-scroll")
    assert_selector(".f-c-form-layout__file-pickers", text: "Picker")
  end

  def test_render_with_header
    component = Folio::Console::Form::LayoutComponent.new
    component.with_header { "Header" }

    render_inline(component) { "Content" }

    assert_selector(".f-c-form-layout__grid-item.f-c-form-layout__grid-item--header",
                    text: "Header")
  end
end

# frozen_string_literal: true

require "test_helper"

class Folio::Publishable::HintComponentTest < Folio::ComponentTest
  test "does not render for published record" do
    page = create(:folio_page, published: true)

    render_inline(Folio::Publishable::HintComponent.new(record: page))

    assert_no_selector(".f-publishable-hint")
  end

  test "renders for unpublished record" do
    page = create(:folio_page, published: false)

    render_inline(Folio::Publishable::HintComponent.new(record: page))

    assert_selector(".f-publishable-hint")
  end

  test "does not render when record is nil and force is false" do
    render_inline(Folio::Publishable::HintComponent.new(record: nil))

    assert_no_selector(".f-publishable-hint")
  end

  test "renders when force is true" do
    render_inline(Folio::Publishable::HintComponent.new(force: true))

    assert_selector(".f-publishable-hint")
  end

  test "renders custom hint when provided" do
    page = create(:folio_page, published: false)
    custom_hint = "Custom warning message"

    render_inline(Folio::Publishable::HintComponent.new(record: page, hint: custom_hint))

    assert_selector(".f-publishable-hint")
    assert_text(custom_hint)
  end
end

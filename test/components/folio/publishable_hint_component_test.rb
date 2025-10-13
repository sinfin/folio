# frozen_string_literal: true

require "test_helper"

class Folio::PublishableHintComponentTest < Folio::ComponentTest
  def test_render_with_boolean
    model = true

    render_inline(Folio::PublishableHintComponent.new(model:))

    assert_selector(".folio-publishable-hint")
  end

  def test_render_with_unpublished_page
    page = create(:folio_page, published: false)

    render_inline(Folio::PublishableHintComponent.new(model: page))

    assert_selector(".folio-publishable-hint")
  end

  def test_not_render_with_published_page
    page = create(:folio_page, published: true)

    render_inline(Folio::PublishableHintComponent.new(model: page))

    assert_no_selector(".folio-publishable-hint")
  end

  def test_not_render_with_nil_model
    render_inline(Folio::PublishableHintComponent.new(model: nil))

    assert_no_selector(".folio-publishable-hint")
  end
end

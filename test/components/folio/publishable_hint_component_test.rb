# frozen_string_literal: true

require "test_helper"

class Folio::PublishableHintComponentTest < Folio::ComponentTest
  def test_render_with_force
    render_inline(Folio::PublishableHintComponent.new(force: true))

    assert_selector(".folio-publishable-hint")
  end

  def test_render_with_unpublished_page
    page = create(:folio_page, published: false)

    render_inline(Folio::PublishableHintComponent.new(record: page))

    assert_selector(".folio-publishable-hint")
  end

  def test_not_render_with_published_page
    page = create(:folio_page, published: true)

    render_inline(Folio::PublishableHintComponent.new(record: page))

    assert_no_selector(".folio-publishable-hint")
  end

  def test_not_render_with_nil_record
    render_inline(Folio::PublishableHintComponent.new(record: nil))

    assert_no_selector(".folio-publishable-hint")
  end

  def test_render_with_force_overrides_published_page
    page = create(:folio_page, published: true)

    render_inline(Folio::PublishableHintComponent.new(record: page, force: true))

    assert_selector(".folio-publishable-hint")
  end
end

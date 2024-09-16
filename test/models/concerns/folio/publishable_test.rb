# frozen_string_literal: true

require "test_helper"

class Folio::PublishableTest < ActiveSupport::TestCase
  class PagePublishableWithDate < Folio::Page
    def self.require_published_date_for_publishing?
      true
    end
  end

  test "with_date" do
    assert_equal(0, Folio::Page.published.count)
    assert_equal(0, Folio::Page.unpublished.count)
    assert_equal(0, Folio::Page.published_or_admin(true).count)
    assert_equal(0, Folio::Page.published_or_admin(false).count)

    page = create(:folio_page, :unpublished)
    assert_equal(0, Folio::Page.published.count)
    assert_equal(1, Folio::Page.unpublished.count)
    assert_equal(1, Folio::Page.published_or_admin(true).count)
    assert_equal(0, Folio::Page.published_or_admin(false).count)

    page.update!(published: true, published_at: nil)
    assert_equal(1, Folio::Page.published.count)
    assert_equal(0, Folio::Page.unpublished.count)
    assert_equal(1, Folio::Page.published_or_admin(true).count)
    assert_equal(1, Folio::Page.published_or_admin(false).count)

    page.update!(published: false, published_at: 1.hour.ago)
    assert_equal(0, Folio::Page.published.count)
    assert_equal(1, Folio::Page.unpublished.count)
    assert_equal(1, Folio::Page.published_or_admin(true).count)
    assert_equal(0, Folio::Page.published_or_admin(false).count)

    page.update!(published: true, published_at: 1.hour.ago)
    assert_equal(1, Folio::Page.published.count)
    assert_equal(0, Folio::Page.unpublished.count)
    assert_equal(1, Folio::Page.published_or_admin(true).count)
    assert_equal(1, Folio::Page.published_or_admin(false).count)

    page.update!(published: true, published_at: 1.hour.from_now)
    assert_equal(0, Folio::Page.published.count)
    assert_equal(1, Folio::Page.unpublished.count)
    assert_equal(1, Folio::Page.published_or_admin(true).count)
    assert_equal(0, Folio::Page.published_or_admin(false).count)
  end

  test "set_published_date_automatically" do
    regular_page = create(:folio_page,
                          published: false,
                          published_at: nil)

    assert_equal false, regular_page.published
    assert_equal false, regular_page.published?
    assert_nil regular_page.published_at
    assert_not Folio::Page.published.exists?(id: regular_page.id)

    regular_page.update!(published: true)

    assert_equal true, regular_page.published
    assert_equal true, regular_page.published?
    assert_nil regular_page.published_at
    assert Folio::Page.published.exists?(id: regular_page.id)

    page_with_date = create_page_singleton(PagePublishableWithDate,
                                           published: false,
                                           published_at: nil)

    assert_equal false, page_with_date.published
    assert_equal false, page_with_date.published?
    assert_nil page_with_date.published_at
    assert_not PagePublishableWithDate.published.exists?(id: page_with_date.id)

    page_with_date.update_column(:published, true)
    page_with_date.reload

    assert_equal true, page_with_date.published
    assert_equal false, page_with_date.published?
    assert_nil page_with_date.published_at
    assert_not PagePublishableWithDate.published.exists?(id: page_with_date.id)

    page_with_date.update!(published: true)

    assert_equal true, page_with_date.published
    assert_equal true, page_with_date.published?
    assert page_with_date.published_at
    assert PagePublishableWithDate.published.exists?(id: page_with_date.id)
  end
end

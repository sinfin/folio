# frozen_string_literal: true

require 'test_helper'

class Folio::PublishableTest < ActiveSupport::TestCase
  test 'with_date' do
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
end

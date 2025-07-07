# frozen_string_literal: true

require "test_helper"

class Folio::PublishableTest < ActiveSupport::TestCase
  class PagePublishableWithDate < Folio::Page
    def self.require_published_date_for_publishing?
      true
    end
  end

  class PublishableTemplateObject
    def self.before_validation(_action)
    end

    def self.scope(*args, &block)
    end

    def initialize
      @published = false
      @published_at = nil
      @published_from = nil
      @published_until = nil
    end

    def generate_preview_token
      "preview_token"
    end

    def save!(*args) # for publish! and unpublish!
    end
  end

  class PublishableBasicObject < PublishableTemplateObject
    attr_accessor :published

    include Folio::Publishable::Basic
  end

  class PublishableWithDateObject < PublishableTemplateObject
    attr_accessor :published, :published_at

    include Folio::Publishable::WithDate
  end

  class PublishableWithinObject < PublishableTemplateObject
    attr_accessor :published, :published_from, :published_until

    include Folio::Publishable::Within
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


  test "publishable_basic" do
    object = PublishableBasicObject.new
    assert_equal false, object.published
    assert_equal false, object.published?

    object.publish

    assert_equal true, object.published
    assert_equal true, object.published?

    object.unpublish

    assert_equal false, object.published
    assert_equal false, object.published?
  end

  test "publishable_with_date" do
    object = PublishableWithDateObject.new
    assert_equal false, object.published
    assert_nil object.published_at
    assert_equal false, object.published?

    object.published_at = 1.hour.ago
    assert_equal false, object.published
    assert_equal false, object.published?

    object.published = true
    assert_equal true, object.published?

    object.published_at = Time.current + 1.hour
    assert_equal true, object.published
    assert_equal false, object.published?

    object.unpublish

    assert_equal false, object.published
    assert_not_nil object.published_at # we keep the date
    assert_equal false, object.published?

    object.published_at = nil

    t = Time.current
    Time.stub(:current, t) do
      object.publish
    end

    assert_equal true, object.published
    assert_equal true, object.published?
    assert_equal t, object.published_at

    object.unpublish

    assert_equal false, object.published?

    t = Time.current + 10.minutes
    object.publish(published_at: t)

    assert_equal true, object.published
    assert_equal t, object.published_at
    assert_equal false, object.published?
  end

  test "publishable_within" do
    object = PublishableWithinObject.new
    assert_equal false, object.published
    assert_nil object.published_from
    assert_nil object.published_until
    assert_equal false, object.published?

    object.published = true

    assert_nil object.published_from
    assert_nil object.published_until
    assert_equal true, object.published?

    object.published_from = 1.hour.ago
    assert_equal true, object.published
    assert_nil object.published_until
    assert_equal true, object.published?

    object.published_from = 1.minute.from_now
    assert_equal false, object.published?

    object.published_until = 2.minutes.from_now
    assert_equal false, object.published?

    object.published_from = 10.minutes.ago
    assert_equal true, object.published?

    object.published_until = 2.minutes.ago
    assert_equal false, object.published?

    object.published_until = 1.minute.from_now
    object.published_from = nil
    assert_equal true, object.published?

    object.published = false
    assert_equal false, object.published?

    object.published_from = nil
    object.published_until = nil
    assert_equal false, object.published

    object.publish!

    assert_equal true, object.published?
    assert_equal true, object.published
    assert_nil object.published_from
    assert_nil object.published_until

    object.unpublish!

    assert_equal false, object.published?
    assert_equal false, object.published


    t = 1.minute.from_now
    object.publish!(published_from: t)

    assert_equal false, object.published? # future published_from
    assert_equal true, object.published
    assert_equal t, object.published_from
    assert_nil object.published_until

    object.unpublish!

    assert_equal false, object.published
    assert_equal t, object.published_from

    t2 = 2.minutes.ago

    object.publish!(published_from: t2, published_until: t)

    assert_equal true, object.published?
    assert_equal true, object.published
    assert_equal t2, object.published_from
    assert_equal t, object.published_until
  end
end

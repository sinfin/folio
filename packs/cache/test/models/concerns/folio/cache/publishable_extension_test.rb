# frozen_string_literal: true

require "test_helper"

class Folio::Cache::PublishableExtensionTest < ActiveSupport::TestCase
  # Test model for Basic publishable
  class TestBasicModel < Dummy::Blog::Topic
  end

  # Test model for WithDate publishable
  class TestWithDateModel < Dummy::Blog::Article
  end

  # Test model for Within publishable (without site for simplicity)
  class TestWithinModel < Dummy::TestRecord
    include Folio::Publishable::Within

    def self.use_preview_tokens?
      false
    end
  end

  test "Basic publishable returns nil for folio_cache_expires_at" do
    site = create_site

    assert_nil TestBasicModel.folio_cache_expires_at(site:)
  end

  test "Basic publishable returns nil even with published records" do
    site = create_site
    create(:dummy_blog_topic, site:, published: true)

    assert_nil TestBasicModel.folio_cache_expires_at(site:)
  end

  test "WithDate publishable returns nil when no future published_at exists" do
    site = create_site
    create(:dummy_blog_article, site:, published: true, published_at: 1.day.ago)

    assert_nil TestWithDateModel.folio_cache_expires_at(site:)
  end

  test "WithDate publishable returns minimum future published_at" do
    site = create_site
    future_date1 = 2.days.from_now
    future_date2 = 1.day.from_now
    future_date3 = 3.days.from_now

    create(:dummy_blog_article, site:, published: true, published_at: future_date1)
    create(:dummy_blog_article, site:, published: true, published_at: future_date2)
    create(:dummy_blog_article, site:, published: true, published_at: future_date3)

    expires_at = TestWithDateModel.folio_cache_expires_at(site:)
    assert_equal future_date2.to_i, expires_at.to_i
  end

  test "WithDate publishable ignores unpublished records" do
    site = create_site
    future_date = 1.day.from_now

    create(:dummy_blog_article, site:, published: false, published_at: future_date)
    create(:dummy_blog_article, site:, published: true, published_at: future_date)

    expires_at = TestWithDateModel.folio_cache_expires_at(site:)
    assert_equal future_date.to_i, expires_at.to_i
  end

  test "WithDate publishable ignores past published_at" do
    site = create_site
    past_date = 1.day.ago
    future_date = 1.day.from_now

    create(:dummy_blog_article, site:, published: true, published_at: past_date)
    create(:dummy_blog_article, site:, published: true, published_at: future_date)

    expires_at = TestWithDateModel.folio_cache_expires_at(site:)
    assert_equal future_date.to_i, expires_at.to_i
  end

  test "WithDate publishable filters by site when model belongs to site" do
    site1 = create_site
    site2 = create_site(force: true)
    future_date1 = 1.day.from_now
    future_date2 = 2.days.from_now

    create(:dummy_blog_article, site: site1, published: true, published_at: future_date1)
    create(:dummy_blog_article, site: site2, published: true, published_at: future_date2)

    expires_at = TestWithDateModel.folio_cache_expires_at(site: site1)
    assert_equal future_date1.to_i, expires_at.to_i
  end

  test "Within publishable returns nil when no future dates exist" do
    site = create_site
    TestWithinModel.create!(published: true, published_from: 1.day.ago, published_until: 2.days.ago)

    assert_nil TestWithinModel.folio_cache_expires_at(site:)
  end

  test "Within publishable returns minimum future published_from" do
    site = create_site
    future_from1 = 2.days.from_now
    future_from2 = 1.day.from_now
    future_from3 = 3.days.from_now

    TestWithinModel.create!(published: false, published_from: future_from1)
    TestWithinModel.create!(published: false, published_from: future_from2)
    TestWithinModel.create!(published: false, published_from: future_from3)

    expires_at = TestWithinModel.folio_cache_expires_at(site:)
    assert_equal future_from2.to_i, expires_at.to_i
  end

  test "Within publishable returns minimum future published_until for published records" do
    site = create_site
    future_until1 = 2.days.from_now
    future_until2 = 1.day.from_now
    future_until3 = 3.days.from_now

    TestWithinModel.create!(published: true, published_from: 1.day.ago, published_until: future_until1)
    TestWithinModel.create!(published: true, published_from: 1.day.ago, published_until: future_until2)
    TestWithinModel.create!(published: true, published_from: 1.day.ago, published_until: future_until3)

    expires_at = TestWithinModel.folio_cache_expires_at(site:)
    assert_equal future_until2.to_i, expires_at.to_i
  end

  test "Within publishable returns earliest of published_from or published_until" do
    site = create_site
    future_from = 1.day.from_now
    future_until = 2.days.from_now

    TestWithinModel.create!(published: false, published_from: future_from)
    TestWithinModel.create!(published: true, published_from: 1.day.ago, published_until: future_until)

    expires_at = TestWithinModel.folio_cache_expires_at(site:)
    assert_equal future_from.to_i, expires_at.to_i
  end

  test "Within publishable ignores past published_from" do
    site = create_site
    past_from = 1.day.ago
    future_from = 1.day.from_now

    TestWithinModel.create!(published: false, published_from: past_from)
    TestWithinModel.create!(published: false, published_from: future_from)

    expires_at = TestWithinModel.folio_cache_expires_at(site:)
    assert_equal future_from.to_i, expires_at.to_i
  end

  test "Within publishable ignores past published_until" do
    site = create_site
    past_until = 1.day.ago
    future_until = 1.day.from_now

    TestWithinModel.create!(published: true, published_from: 2.days.ago, published_until: past_until)
    TestWithinModel.create!(published: true, published_from: 2.days.ago, published_until: future_until)

    expires_at = TestWithinModel.folio_cache_expires_at(site:)
    assert_equal future_until.to_i, expires_at.to_i
  end

  test "Within publishable ignores unpublished records for published_until check" do
    site = create_site
    future_until = 1.day.from_now

    TestWithinModel.create!(published: false, published_from: 1.day.ago, published_until: future_until)
    TestWithinModel.create!(published: true, published_from: 1.day.ago, published_until: future_until)

    expires_at = TestWithinModel.folio_cache_expires_at(site:)
    assert_equal future_until.to_i, expires_at.to_i
  end
end

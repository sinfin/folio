# frozen_string_literal: true

require "test_helper"

class Folio::FriendlyIdWithLocaleTest < ActiveSupport::TestCase
  class TestPage < Dummy::Blog::LocalizedPage
    include Folio::FriendlyIdWithLocale
    translates :slug
    def self.slug_additional_classes
      [Folio::Site]
    end
  end

  class TestPage2 < Dummy::Blog::LocalizedPage
    include Folio::FriendlyIdWithLocale
    translates :slug
    def self.slug_additional_classes
      []
    end
  end

  class TestArticle < Dummy::Blog::LocalizedArticle
    include Folio::FriendlyIdWithLocale
    translates :slug
    def self.slug_additional_classes
      [Dummy::Blog::LocalizedPage]
    end
  end

  test "should generate next slug if slug already exists" do
    I18n.locale = :cs
    site = get_any_site
    site.update!(slug: "test-site")
    page1 = TestPage.create(title: "Test Title", site:, locale: I18n.locale)
    page2 = TestPage2.create(title: "Test Site", site:, locale: I18n.locale)

    article1 = TestArticle.create(title: "Test Title", site:, locale: I18n.locale)
    I18n.locale = :en
    article2 = TestArticle.create(title: "Test Title", site:, locale: I18n.locale)

    assert_not_nil page1.slug
    assert_not_nil page2.slug
    assert_not_nil article1.slug
    assert_not_nil article2.slug
    assert_match(/[0-9a-z-]+/, page1.slug)
    assert_match(/[0-9a-z-]+/,  page2.slug)
    assert_not_equal article1.slug, page2.slug
    assert_not_equal article1.slug, article2.slug
    assert_equal page1.slug, article2.slug
  end

  test "should generate already existing slug" do
    site = get_any_site
    site.update!(slug: "test-site")
    article = TestArticle.create(title: "Test Site", site:)
    page = TestPage2.create(title: "Test Site", site:)
    assert_not_nil page.slug
    assert_match(/[0-9a-z-]+/, page.slug)
    assert_equal article.slug, page.slug
  end
end

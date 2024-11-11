# frozen_string_literal: true

require "test_helper"

class Folio::FriendlyIdTest < ActiveSupport::TestCase
  class TestPage < Folio::Page
    def self.slug_additional_classes
      [Folio::Site]
    end
  end

  class TestPage2 < Folio::Page
    def self.slug_additional_classes
      []
    end
  end

  class TestArticle < Dummy::Blog::Article
    def self.slug_additional_classes
      [Folio::Page, Dummy::Blog::Article]
    end
  end

  test "should generate next slug if slug already exists" do
    site = get_any_site
    site.update!(slug: "test-site")

    page1 = TestPage.create(title: "Test Title", site:)
    page2 = TestPage2.create(title: "Test Site", site:)

    article1 = TestArticle.create(title: "Test Title", site:, perex: "Test Perex")
    article2 = TestArticle.create(title: "Test Title", site:, perex: "Test Perex")

    assert_not_nil page1.slug
    assert_not_nil page2.slug
    assert_not_nil article1.slug
    assert_not_nil article2.slug
    assert_match(/[0-9a-z-]+/, page1.slug)
    assert_match(/[0-9a-z-]+/,  page2.slug)
    assert_not_equal article1.slug, page2.slug
    assert_not_equal article1.slug, article2.slug
  end

  test "should generate already existing slug" do
    site = get_any_site
    site.update!(slug: "test-site")
    article = TestArticle.create(title: "Test Site", site:, perex: "Test Perex")
    page = TestPage2.create(title: "Test Site", site:)

    assert_not_nil page.slug
    assert_match(/[0-9a-z-]+/, page.slug)
    assert_equal article.slug, page.slug
  end

  test "respect slug from input" do
    site = get_any_site
    article = TestArticle.create(title: "Test Site", site:, perex: "Test Perex", slug: "test-slug")

    assert_equal "test-slug", article.slug
    assert article.update(slug: "test-slug")
  end
end

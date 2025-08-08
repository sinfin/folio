# frozen_string_literal: true

require "test_helper"

class Folio::FriendlyIdTest < ActiveSupport::TestCase
  class TestPage < Folio::Page
    def self.slug_validation_additional_classes
      [Folio::Site]
    end
  end

  class TestPage2 < Folio::Page
    def self.slug_validation_additional_classes
      []
    end
  end

  class TestArticle < Dummy::Blog::Article
    def self.slug_validation_additional_classes
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

  test "should validate slug uniqueness across multiple classes" do
    site = get_any_site
    page = create(:folio_page, slug: "test", site:)
    article = TestArticle.create(title: "Test Article", slug: "test", site:, perex: "Test Perex")

    # page with same slug exists, slug isn't valid
    assert_equal 1, FriendlyId::Slug.where(slug: "test").count
    assert article.errors.added?(:slug, :slug_not_unique_across_classes, sluggable_name: page.title, sluggable_type: page.model_name.human)

    page.update!(slug: "foo")

    # history slug exists, but it will be deleted, slug is valid
    assert_equal 1, FriendlyId::Slug.where(slug: "test").count
    assert article.update!(slug: "test")
    assert_equal 1, FriendlyId::Slug.where(slug: "test").count
  end
end

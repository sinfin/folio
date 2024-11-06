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

  test "should generate next slug if slug already exists" do
    site = get_any_site
    site.update!(slug: "test-site")
    test_1 = TestPage.create(title: "Test Title", site:)
    test_2 = TestPage.create(title: "Test Site", site:)

    assert_not_nil test_1.slug
    assert_not_nil test_2.slug
    assert_match(/[0-9a-z-]+/, test_1.slug)
    assert_match(/[0-9a-z-]+/, test_2.slug)
    assert_not_equal site.slug, test_2.slug
  end

  test "should generate already existing slug" do
    site = get_any_site
    site.update!(slug: "test-site")
    test_2 = TestPage2.create(title: "Test Site", site:)
    assert_not_nil test_2.slug
    assert_match(/[0-9a-z-]+/, test_2.slug)
    assert_equal site.slug, test_2.slug
  end
end

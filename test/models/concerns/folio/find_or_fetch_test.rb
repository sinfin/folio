# frozen_string_literal: true

require "test_helper"

module Folio
  class FindOrFetchTest < ActiveSupport::TestCase
    test "find_or_fetch loads by id" do
      site = create_site
      page = create(:folio_page, site:)

      assert_equal page, Folio::Page.find_or_fetch(page.id)
    end

    test "find_or_fetch with published true raises for unpublished page" do
      site = create_site
      page = create(:folio_page, :unpublished, site:)

      assert_raises(ActiveRecord::RecordNotFound) do
        Folio::Page.find_or_fetch(page.slug, published: true, site:)
      end
    end

    test "find_or_fetch with wrong site raises" do
      site = create_site
      other = create(:dummy_site)
      page = create(:folio_page, site:)

      assert_raises(ActiveRecord::RecordNotFound) do
        Folio::Page.find_or_fetch(page.slug, site: other)
      end
    end

    test "find_or_fetch with with hash filters attributes" do
      skip if Rails.application.config.folio_using_traco

      site = create_site
      page = create(:folio_page, site:, locale: "cs")

      assert_equal page,
                   Folio::Page.find_or_fetch(page.slug, site:, with: { locale: "cs" })

      assert_raises(ActiveRecord::RecordNotFound) do
        Folio::Page.find_or_fetch(page.slug, site:, with: { locale: "en" })
      end
    end

    test "find_or_fetch raises when :site is unsupported" do
      site = create_site

      err = assert_raises(ArgumentError) do
        Folio::Site.find_or_fetch(site.id, site:)
      end
      assert_match(/does not support :site/, err.message)
    end

    test "find_or_fetch raises when :published is unsupported" do
      site = create_site

      err = assert_raises(ArgumentError) do
        Folio::Site.find_or_fetch(site.id, published: true)
      end
      assert_match(/does not support :published/, err.message)
    end
  end
end

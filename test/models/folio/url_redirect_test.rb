# frozen_string_literal: true

require "test_helper"

class Folio::UrlRedirectTest < ActiveSupport::TestCase
  test "validate url format" do
    fur = build(:folio_url_redirect)
    assert fur.valid?

    %w[
      foo
      ftp://foo
    ].each do |url_from|
      fur.url_from = url_from

      assert_not fur.valid?, "url_from - #{url_from}"
      assert_equal :url_from, fur.errors.first.attribute
      assert_equal :invalid, fur.errors.first.type
    end

    %w[
      /foo
      http://foo
      https://foo
    ].each do |url_from|
      fur.url_from = url_from
      assert fur.valid?, "url_from - #{url_from}"
    end
  end

  test "validate url across records" do
    I18n.with_locale(:en) do
      site = get_any_site

      create(:folio_url_redirect, url_from: "/foo", url_to: "/bar", site:)

      fur = build(:folio_url_redirect, url_from: "/bar", url_to: "/baz", site:)

      assert_not fur.valid?
      assert_equal "Redirect from cannot be the same as \"Redirect to\" of another redirect",
                   fur.errors.full_messages.join(". ")
    end
  end

  test "folio_url_redirects_per_site" do
    I18n.with_locale(:en) do
      site_1 = create_site(force: true)
      site_2 = create_site(force: true)

      create(:folio_url_redirect, url_from: "/foo", url_to: "/bar", site: site_1)

      fur = build(:folio_url_redirect, url_from: "/foo", url_to: "/bar", site: site_2)

      Rails.application.config.stub(:folio_url_redirects_per_site, true) do
        assert fur.valid?

        fur.site = site_1
        assert_not fur.valid?

        assert_equal "Redirect to has already been taken. Redirect from has already been taken",
                     fur.errors.full_messages.join(". ")
      end

      Rails.application.config.stub(:folio_url_redirects_per_site, false) do
        fur.site = site_1
        assert_not fur.valid?

        assert_equal "Redirect to has already been taken. Redirect from has already been taken",
                     fur.errors.full_messages.join(". ")

        fur.site = site_2
        assert_not fur.valid?

        assert_equal "Redirect to has already been taken. Redirect from has already been taken",
                     fur.errors.full_messages.join(". ")
      end
    end
  end
end

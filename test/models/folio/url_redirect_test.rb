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

  test "redirect_hash" do
    Rails.application.config.stub(:folio_url_redirects_enabled, true) do
      site_1 = create_site(force: true, attributes: { domain: "1.localhost" })
      site_2 = create_site(force: true, attributes: { domain: "2.localhost" })

      a = create(:folio_url_redirect,
                 url_from: "/a",
                 url_to: "/aa",
                 site: site_1,
                 status_code: 301,
                 include_query: true)

      b = create(:folio_url_redirect,
                 url_from: "/b",
                 url_to: "/bb",
                 site: site_2,
                 status_code: 301,
                 include_query: true)

      c = create(:folio_url_redirect,
                 url_from: "/c",
                 url_to: "/cc",
                 site: site_2,
                 status_code: 301,
                 include_query: true)

      Rails.application.config.stub(:folio_url_redirects_per_site, false) do
        assert_equal({
          "*" => {
            "/a" => { url_to: "/aa", status_code: 301, include_query: true },
            "/b" => { url_to: "/bb", status_code: 301, include_query: true },
            "/c" => { url_to: "/cc", status_code: 301, include_query: true },
          }
        }, Folio::UrlRedirect.redirect_hash)
      end

      Rails.application.config.stub(:folio_url_redirects_per_site, true) do
        assert_equal({
          "1.localhost" => {
            "/a" => { url_to: "/aa", status_code: 301, include_query: true },
          },
          "2.localhost" => {
            "/b" => { url_to: "/bb", status_code: 301, include_query: true },
            "/c" => { url_to: "/cc", status_code: 301, include_query: true },
          }
        }, Folio::UrlRedirect.redirect_hash)
      end

      c.update!(published: false)

      Rails.application.config.stub(:folio_url_redirects_per_site, false) do
        assert_equal({
          "*" => {
            "/a" => { url_to: "/aa", status_code: 301, include_query: true },
            "/b" => { url_to: "/bb", status_code: 301, include_query: true },
          }
        }, Folio::UrlRedirect.redirect_hash)
      end

      Rails.application.config.stub(:folio_url_redirects_per_site, true) do
        assert_equal({
          "1.localhost" => {
            "/a" => { url_to: "/aa", status_code: 301, include_query: true },
          },
          "2.localhost" => {
            "/b" => { url_to: "/bb", status_code: 301, include_query: true },
          }
        }, Folio::UrlRedirect.redirect_hash)
      end

      a.update!(published: false)
      b.update!(published: false)


      Rails.application.config.stub(:folio_url_redirects_per_site, false) do
        assert_nil Folio::UrlRedirect.redirect_hash
      end

      Rails.application.config.stub(:folio_url_redirects_per_site, true) do
        assert_nil Folio::UrlRedirect.redirect_hash
      end
    end
  end

  # test "handle_env" do
  #   site_1 = create_site(force: true, attributes: { domain: "1.localhost" })
  #   site_2 = create_site(force: true, attributes: { domain: "2.localhost" })

  #   create(:folio_url_redirect,
  #              url_from: "/a",
  #              url_to: "/aa",
  #              site: site_1,
  #              status_code: 301,
  #              include_query: true)

  #   create(:folio_url_redirect,
  #              url_from: "http://2.localhost/b",
  #              url_to: "http://2.localhost/bb",
  #              site: site_2,
  #              status_code: 301,
  #              include_query: true)

  #   create(:folio_url_redirect,
  #              url_from: "http://2.localhost/c",
  #              url_to: "http://2.localhost/cc",
  #              site: site_2,
  #              status_code: 301,
  #              include_query: false)

  #   Rails.application.config.stub(:folio_url_redirects_enabled, true) do
  #     Rails.application.config.stub(:folio_url_redirects_per_site, false) do
  #       {
  #         "http://1.localhost/a?foo=bar" => nil,
  #         "http://1.localhost/a" => "http://1.localhost/aa",
  #       }.each do |from, to|
  #         result = Folio::UrlRedirect.handle_env(Rack::MockRequest.env_for(from))

  #         if to.nil?
  #           assert_nil result, "#{from} -> nil"
  #         else
  #           assert_equal [301, { "Location" => to }, []], result, "#{from} -> #{to}"
  #         end
  #       end
  #     end
  #   end
  # end
end
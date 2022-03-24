# frozen_string_literal: true

require "test_helper"

class Folio::BelongsToSiteTest < ActiveSupport::TestCase
  module Custom
    class Site < Folio::Site
    end

    class Page < Folio::Page
    end
  end

  module Other
    class Page < Folio::Page
    end
  end

  test "validate_belongs_to_site" do
    folio_site_is_a_singleton = Rails.application.config.folio_site_is_a_singleton
    folio_site_validate_belongs_to_namespace = Rails.application.config.folio_site_validate_belongs_to_namespace

    Rails.application.config.folio_site_is_a_singleton = false
    Rails.application.config.folio_site_validate_belongs_to_namespace = true

    assert site = Custom::Site.create!(title: "Custom::Site",
                                       email: "custom@site.site",
                                       locale: "cs",
                                       locales: ["cs"])

    custom_page = Custom::Page.new(title: "Custom::Page")
    assert_not custom_page.valid?

    assert_equal :site, custom_page.errors.first.attribute
    assert_equal :blank, custom_page.errors.first.type

    custom_page.site = site

    assert custom_page.valid?

    other_page = Other::Page.new(title: "Other::Page")
    assert_not other_page.valid?

    assert_equal :site, other_page.errors.first.attribute
    assert_equal :blank, other_page.errors.first.type

    other_page.site = site

    assert_not other_page.valid?
    assert_equal :base, other_page.errors.first.attribute
    assert_equal :wrong_namespace, other_page.errors.first.type

    Rails.application.config.folio_site_validate_belongs_to_namespace = false

    assert other_page.valid?

    Rails.application.config.folio_site_is_a_singleton = folio_site_is_a_singleton
    Rails.application.config.folio_site_validate_belongs_to_namespace = folio_site_validate_belongs_to_namespace
  end
end

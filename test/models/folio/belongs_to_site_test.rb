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
    assert site = Custom::Site.create!(title: "Custom::Site",
                                       email: "custom@site.site",
                                       locale: "cs",
                                       locales: ["cs"])

    custom_page = Custom::Page.new(title: "Custom::Page")

    # not `Custom`` namespace (as site is `Custom::Site`)
    other_page = Other::Page.new(title: "Other::Page")

    Rails.application.config.stub(:folio_site_validate_belongs_to_namespace, true) do
      assert_not custom_page.valid?
      assert_equal :site, custom_page.errors.first.attribute
      assert_equal :blank, custom_page.errors.first.type

      custom_page.site = site

      assert custom_page.valid?

      assert_not other_page.valid?
      assert_equal :site, other_page.errors.first.attribute
      assert_equal :blank, other_page.errors.first.type

      other_page.site = site

      assert_not other_page.valid?
      assert_equal :base, other_page.errors.first.attribute
      assert_equal :wrong_namespace, other_page.errors.first.type
    end

    Rails.application.config.stub(:folio_site_validate_belongs_to_namespace, false) do
      assert other_page.valid?
    end
  end
end

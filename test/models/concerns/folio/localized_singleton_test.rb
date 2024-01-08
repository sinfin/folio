# frozen_string_literal: true

require "test_helper"

class Folio::LocalizedSingletonTest < ActiveSupport::TestCase
  class TestLocalizedSingleton < Dummy::Menu::Header
    include Folio::LocalizedSingleton
  end

  test "allows only one record" do
    singletoned_class = TestLocalizedSingleton
    site = get_any_site

    _allowed_cz = singletoned_class.create!(locale: :cz, title: "Povolený", site:)
    _allowed_en = singletoned_class.create!(locale: :en, title: "Allowed", site:)
    not_allowed = singletoned_class.new(locale: :en, title: "Allowed2", site:)

    assert_not not_allowed.valid?
    I18n.with_locale(site.locale) do
      assert_includes(not_allowed.errors[:type],
                      I18n.t("errors.attributes.type.already_exists_with_locale", class: singletoned_class, rec_locale: "en"),
                      not_allowed.errors.to_json)
    end
  end
end

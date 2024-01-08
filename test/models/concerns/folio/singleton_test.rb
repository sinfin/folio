# frozen_string_literal: true

require "test_helper"

class Folio::SingletonTest < ActiveSupport::TestCase
  test "allows only one record" do
    singletoned_class = Dummy::Menu::Header
    site = get_any_site

    _allowed = singletoned_class.create!(locale: :cz, title: "Povolený", site:)
    not_allowed = singletoned_class.new(locale: :en, title: "Allowed", site:)

    assert_not not_allowed.valid?
    I18n.with_locale(site.locale) do
      assert_includes(not_allowed.errors[:type],
                      I18n.t("errors.attributes.type.already_exists", class: singletoned_class),
                      not_allowed.errors.to_json)
    end
  end
end

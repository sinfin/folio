# frozen_string_literal: true

require "test_helper"

class Folio::LocalizedSingletonTest < ActiveSupport::TestCase
  class TestLocalizedSingleton < Dummy::Menu::Header
    include Folio::LocalizedSingleton
  end

  test "allows only one record" do
    I18n.with_locale(:cs) do
      singletoned_class = TestLocalizedSingleton
      site = get_any_site

      _allowed_cz = singletoned_class.create!(locale: :cz, title: "Povolený", site:)
      _allowed_en = singletoned_class.create!(locale: :en, title: "Allowed", site:)
      not_allowed = singletoned_class.new(locale: :en, title: "Allowed2", site:)

      assert_not not_allowed.valid?
      assert_includes(not_allowed.errors[:type],
                      "Je povolen jen jeden záznam '#{singletoned_class}' s 'locale = \"en\"'.",
                      not_allowed.errors.to_json)
    end
  end
end

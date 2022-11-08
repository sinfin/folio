# frozen_string_literal: true

require "test_helper"

class Folio::LocalizedSingletonTest < ActiveSupport::TestCase
  class TestLocalizedSingleton < Dummy::Menu::Header
    include Folio::LocalizedSingleton
  end

  test "allows only one record" do
    singletoned_class = TestLocalizedSingleton

    _allowed_cz = singletoned_class.create!(locale: :cz, title: "Povolený")
    _allowed_en = singletoned_class.create!(locale: :en, title: "Allowed")
    not_allowed = singletoned_class.new(locale: :en, title: "Allowed2")

    assert_not not_allowed.valid?
    assert_includes(not_allowed.errors[:type],
                    "Je povolen jen jeden záznam '#{singletoned_class}' s 'locale = \"en\"'.",
                    not_allowed.errors.to_json)
  end
end

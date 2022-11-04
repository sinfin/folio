# frozen_string_literal: true

require "test_helper"

class Folio::SingletonTest < ActiveSupport::TestCase
  test "allows only one record" do
    singletoned_class = Dummy::Menu::Header

    _allowed = singletoned_class.create!(locale: :cz, title: "Povolený")
    not_allowed = singletoned_class.new(locale: :en, title: "Allowed")

    assert_not not_allowed.valid?
    assert_includes(not_allowed.errors[:type],
                    "Je povolen jen jeden záznam '#{singletoned_class}'.",
                    not_allowed.errors.to_json)
  end
end

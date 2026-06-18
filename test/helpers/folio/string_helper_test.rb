# frozen_string_literal: true

require "test_helper"

class Folio::StringHelperTest < ActiveSupport::TestCase
  def helpers
    Folio::Console::UsersController.helpers
  end

  test "sanitize strips tags by default" do
    assert_equal "x", helpers.sanitize("<b>x</b>")
  end

  test "sanitize accepts second options argument like Rails" do
    assert_nothing_raised do
      helpers.sanitize("<b>x</b>", {})
    end
  end

  test "sanitize accepts keyword options" do
    assert_equal "x", helpers.sanitize("<b>x</b>", tags: [])
  end

  test "simple_format does not raise with Folio sanitize" do
    note = "foo bar"
    result = helpers.simple_format(note)

    assert_includes result, "<p>"
    assert_includes result, note
  end
end

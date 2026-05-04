# frozen_string_literal: true

require "test_helper"

class Folio::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Folio
  end

  test "optional packs are disabled by default" do
    assert_empty Folio::DEFAULT_ENABLED_PACKS
  end

  test "dummy app opts into AI pack for tests" do
    assert_includes Folio.enabled_packs, :ai
  end
end

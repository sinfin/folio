# frozen_string_literal: true

require "test_helper"

class Folio::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Folio
  end

  test "optional packs are disabled by default" do
    assert_empty Folio::DEFAULT_ENABLED_PACKS
  end

  test "disabled pack assets return no logical asset names" do
    with_enabled_packs do
      assert_empty Folio.enabled_pack_assets(:javascripts)
      assert_empty Folio.enabled_pack_assets(:stylesheets)
    end
  end

  test "console layout includes enabled pack logical assets" do
    head = Folio::Engine.root.join("app/views/layouts/folio/console/_head.slim").read

    assert_includes head, "Folio.enabled_pack_assets(:stylesheets)"
    assert_includes head, "Folio.enabled_pack_assets(:javascripts)"
  end

  private
    def with_enabled_packs(*packs)
      original_packs = Folio.enabled_packs
      Folio.enabled_packs = packs

      yield
    ensure
      Folio.enabled_packs = original_packs
    end
end

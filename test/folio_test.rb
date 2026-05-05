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

  test "enabled pack assets return declared logical asset names" do
    with_enabled_packs(:ai) do
      assert_equal ["folio_pack_ai"], Folio.enabled_pack_assets(:javascripts)
      assert_equal ["folio_pack_ai"], Folio.enabled_pack_assets(:stylesheets)
    end
  end

  test "disabled pack assets return no logical asset names" do
    with_enabled_packs do
      assert_empty Folio.enabled_pack_assets(:javascripts)
      assert_empty Folio.enabled_pack_assets(:stylesheets)
    end
  end

  test "console base assets do not directly include AI pack assets" do
    base_js = Folio::Engine.root.join("app/assets/javascripts/folio/console/base.js").read
    base_sass = Folio::Engine.root.join("app/assets/stylesheets/folio/console/base.sass").read

    assert_not_includes base_js, "folio/console/ai/text_suggestions_component"
    assert_not_includes base_sass, "packs/ai/app/components/folio/console/ai"
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

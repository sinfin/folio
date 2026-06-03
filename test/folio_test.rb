# frozen_string_literal: true

require "test_helper"

class Folio::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Folio
  end

  test "optional packs are disabled by default" do
    assert_empty Folio::DEFAULT_ENABLED_PACKS
  end

  test "dummy app opts into optional packs for tests" do
    assert_includes Folio.enabled_packs, :ai
    assert_includes Folio.enabled_packs, :cloudflare_stream
    assert_includes Folio.enabled_packs, :cra_media_cloud
  end

  test "video provider packs register provider classes" do
    provider_classes = Rails.application.config.folio_files_video_playback_provider_classes

    assert_equal "Folio::CloudflareStream::VideoProvider", provider_classes["cloudflare_stream"]
    assert_equal "Folio::CraMediaCloud::VideoProvider", provider_classes["cra_media_cloud"]
  end

  test "enabled pack assets return declared logical asset names" do
    with_enabled_packs(:ai) do
      assert_equal ["folio_pack_ai"], Folio.enabled_pack_assets(:javascripts)
      assert_equal ["folio_pack_ai"], Folio.enabled_pack_assets(:stylesheets)
    end
  end

  test "enabled pack assets are precompiled with asset type extensions" do
    precompiled_assets = Rails.application.precompiled_assets(true)

    assert_includes precompiled_assets, "folio_pack_ai.js"
    assert_includes precompiled_assets, "folio_pack_ai.css"
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

    assert_not_includes base_js, "folio/ai/console/text_suggestions_component"
    assert_not_includes base_sass, "packs/ai/app/components/folio/ai/console"
  end

  test "console layout includes enabled pack logical assets" do
    head = Folio::Engine.root.join("app/views/layouts/folio/console/_head.slim").read

    assert_includes head, "Folio.enabled_pack_assets(:stylesheets)"
    assert_includes head, "Folio.enabled_pack_assets(:javascripts)"
  end

  test "AI routes are mounted only when AI pack is enabled" do
    with_enabled_packs do
      reload_routes

      assert_raises(ActionController::RoutingError) do
        Folio::Engine.routes.recognize_path("/console/api/ai_text_suggestions/text_suggestions",
                                            method: :post)
      end
    end

    with_enabled_packs(:ai) do
      reload_routes

      route = Folio::Engine.routes.recognize_path("/console/api/ai_text_suggestions/text_suggestions",
                                                  method: :post)

      assert_equal "folio/ai/console/api/text_suggestions", route[:controller]
      assert_equal "text_suggestions", route[:action]
    end
  ensure
    reload_routes
  end

  private
    def with_enabled_packs(*packs)
      original_packs = Folio.enabled_packs
      Folio.enabled_packs = packs

      yield
    ensure
      Folio.enabled_packs = original_packs
    end

    def reload_routes
      Folio::Engine.reload_routes! if Folio::Engine.respond_to?(:reload_routes!)
      Folio::Engine.routes_reloader.reload! if Folio::Engine.respond_to?(:routes_reloader)
      Rails.application.reload_routes!
    end
end

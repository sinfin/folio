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

  test "disabled ai pack does not mount console api route" do
    with_enabled_packs do
      assert_raises(ActionController::RoutingError) do
        Folio::Engine.routes.recognize_path("/console/api/ai/text_suggestions.json",
                                            method: :post)
      end
    end
  end

  test "enabled ai pack mounts console api route" do
    with_enabled_packs(:ai) do
      assert_equal({
                     controller: "folio/ai/console/api/text_suggestions",
                     action: "create",
                     format: "json",
                   }.with_indifferent_access,
                   Folio::Engine.routes.recognize_path("/console/api/ai/text_suggestions.json",
                                                       method: :post).with_indifferent_access)
    end
  end

  private
    def with_enabled_packs(*packs)
      original_packs = Folio.enabled_packs
      Folio.enabled_packs = packs
      reload_routes

      yield
    ensure
      Folio.enabled_packs = original_packs
      reload_routes
    end

    def reload_routes
      Folio::Engine.reload_routes! if Folio::Engine.respond_to?(:reload_routes!)
      Folio::Engine.routes_reloader.reload! if Folio::Engine.respond_to?(:routes_reloader)
      Rails.application.reload_routes!
    end
end

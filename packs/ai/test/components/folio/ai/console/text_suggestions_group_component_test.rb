# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::Console::TextSuggestionsGroupComponentTest < Folio::Console::ComponentTest
  setup do
    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern

    Folio::Ai.reset_registry!
    Folio::Ai.register_record(record_class_name: "Folio::Page",
                              fields: %i[title perex],
                              groups: [
                                {
                                  key: :meta,
                                  label: "Meta fields",
                                  fields: %i[title perex],
                                },
                              ])

    @site = create(Rails.application.config.folio_site_default_test_factory,
                   ai_settings: { "enabled" => true, "provider" => "dummy" })
    @page = create(:folio_page, site: @site)
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "renders group controls around child content" do
    render_component do |form|
      render_inline(Folio::Ai::Console::TextSuggestionsGroupComponent.new(form:,
                                                                         key: :meta)) do
        "Child inputs"
      end
    end

    assert_selector(".f-ai-c-text-suggestions-group", text: "Child inputs")
    assert_selector(".f-ai-c-text-suggestions-group__button", text: "AI suggestions for all variants")
    assert_selector(".f-ai-c-text-suggestions-group__close[aria-label='Close']", visible: :all)
    assert_selector("textarea[placeholder='Custom AI instructions (optional) ...']", visible: :all)

    fields = JSON.parse(page.find(".f-ai-c-text-suggestions-group")["data-f-ai-c-text-suggestions-group-fields-value"])
    assert_equal [
      { "key" => "title", "component_id" => "folio_ai_text_suggestions_page_title" },
      { "key" => "perex", "component_id" => "folio_ai_text_suggestions_page_perex" },
    ], fields
  end

  test "does not render without registered fields" do
    render_component do |form|
      render_inline(Folio::Ai::Console::TextSuggestionsGroupComponent.new(form:,
                                                                         key: :missing))
    end

    assert_no_selector(".f-ai-c-text-suggestions-group")
  end

  private
    def render_component(&block)
      I18n.with_locale(:en) do
        Folio::Ai::Providers::Dummy.stub(:available?, true) do
          vc_test_controller.view_context.simple_form_for(@page, url: "/", &block)
        end
      end
    end
end

# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::Console::SiteSettingsComponentTest < Folio::Console::ComponentTest
  setup do
    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern

    Folio::Ai.reset_registry!
    Folio::Ai.register_record(record_class_name: "Folio::Page",
                              fields: [
                                { key: :title, character_limit: 80 },
                                { key: :perex, character_limit: 400 },
                              ],
                              groups: [
                                {
                                  key: :meta,
                                  label: "Meta fields",
                                  fields: %i[title perex],
                                },
                              ])
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "renders site provider and field prompt settings" do
    site = build(:folio_site,
                 ai_settings: {
                   "enabled" => true,
                   "provider" => "dummy",
                   "model" => "dummy",
                   "integrations" => {
                     "folio_pages" => {
                       "fields" => {
                         "title" => {
                           "prompt" => "Write a short title.",
                         },
                       },
                       "groups" => {
                         "meta" => {
                           "prompt" => "Write title and perex as a set.",
                         },
                       },
                     },
                   },
                 })

    render_component(site)

    assert_selector(".f-ai-c-site-settings")
    assert_selector("input[name$='[ai_settings][enabled]'][value='1']", visible: :all)
    assert_selector("select[name$='[ai_settings][provider]'] option[value='dummy'][selected]")
    assert_selector("select[name$='[ai_settings][model]'] option[value='dummy'][selected]",
                    text: "dummy")
    assert_selector("textarea[name$='[ai_settings][integrations][folio_pages][fields][title][prompt]']",
                    text: "Write a short title.")
    assert_selector("textarea[name$='[ai_settings][integrations][folio_pages][groups][meta][prompt]']",
                    text: "Write title and perex as a set.")
    assert_text(Folio::Page.model_name.human(count: 2))
    assert_text(Folio::Page.human_attribute_name(:title))
    assert_text("Meta fields")
    assert_text("Limit: 80")
  end

  test "renders provider setup message when no providers are available" do
    render_component(build(:folio_site), providers: {})

    assert_selector(".f-ai-c-site-settings .alert-danger")
    assert_no_selector(".f-ai-c-site-settings select")
    assert_no_selector(".f-ai-c-site-settings textarea")
  end

  test "does not render when AI config is disabled" do
    Folio::Ai.config.stub(:enabled?, false) do
      render_component(build(:folio_site))
    end

    assert_no_selector(".f-ai-c-site-settings")
  end

  test "keeps saved model values in the model select" do
    site = build(:folio_site,
                 ai_settings: {
                   "provider" => "dummy",
                   "model" => "custom-dummy",
                 })

    render_component(site)

    assert_selector("select[name$='[ai_settings][model]'] option[value='custom-dummy'][selected]",
                    text: "custom-dummy")
  end

  test "renders model options from the selected provider" do
    site = build(:folio_site,
                 ai_settings: {
                   "provider" => "openai",
                 })

    Folio::Ai::Providers::OpenAi.stub(:models_env_value, "gpt-5.5,gpt-5.5-pro") do
      render_component(site, providers: { openai: Folio::Ai::Providers::OpenAi })
    end

    assert_selector("select[name$='[ai_settings][model]'] option[value='gpt-5.5']",
                    text: "gpt-5.5")
    assert_selector("select[name$='[ai_settings][model]'] option[value='gpt-5.5-pro']",
                    text: "gpt-5.5-pro")
  end

  private
    def render_component(site, providers: { dummy: Folio::Ai::Providers::Dummy })
      Folio::Ai.stub(:available_providers, providers) do
        vc_test_controller.view_context.simple_form_for(site, url: "/") do |form|
          render_inline(Folio::Ai::Console::SiteSettingsComponent.new(form:))
        end
      end
    end
end

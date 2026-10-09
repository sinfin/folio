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
                           "enabled" => false,
                           "prompt" => "Write a short title.",
                         },
                       },
                       "groups" => {
                         "meta" => {
                           "enabled" => true,
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
    assert_selector("select[name$='[ai_settings][model]'] option[value=''][selected]",
                    text: /dummy/)
    assert_selector("textarea[name$='[ai_settings][integrations][folio_pages][fields][title][prompt]']",
                    text: "Write a short title.")
    assert_selector("textarea[name$='[ai_settings][integrations][folio_pages][groups][meta][prompt]']",
                    text: "Write title and perex as a set.")
    title_enabled = page.find("input[type='checkbox'][name$='[ai_settings][integrations][folio_pages][fields][title][enabled]'][value='1']",
                              visible: :all)
    meta_enabled = page.find("input[type='checkbox'][name$='[ai_settings][integrations][folio_pages][groups][meta][enabled]'][value='1']",
                             visible: :all)

    assert_not title_enabled.checked?
    assert meta_enabled.checked?
    assert_text(Folio::Page.model_name.human(count: 2))
    assert_text(Folio::Page.human_attribute_name(:title))
    assert_text("Meta fields")
    assert_text("Limit: 80")
  end

  test "renders provider model data for switching providers" do
    site = build(:folio_site,
                 ai_settings: {
                   "provider" => "dummy",
                   "model" => "dummy",
                 })

    Folio::Ai::Providers::OpenAi.stub(:models_env_value, "gpt-5.5,gpt-5.5-pro") do
      render_component(site,
                       providers: {
                         dummy: Folio::Ai::Providers::Dummy,
                         openai: Folio::Ai::Providers::OpenAi,
                       })
    end

    providers = JSON.parse(page.find(".f-ai-c-site-settings")["data-f-ai-c-site-settings-providers-value"])

    assert_equal "dummy", providers.dig("dummy", "defaultModel")
    assert_includes providers.dig("dummy", "defaultLabel"), "dummy"
    assert_equal [], providers.dig("dummy", "models")
    assert_equal "gpt-5.5", providers.dig("openai", "defaultModel")
    assert_includes providers.dig("openai", "defaultLabel"), "gpt-5.5"
    assert_equal %w[gpt-5.5-pro], providers.dig("openai", "models")
  end

  test "renders provider setup message when no providers are available" do
    render_component(build(:folio_site), providers: {})

    assert_selector(".f-ai-c-site-settings .f-c-ui-alert--danger")
    assert_no_selector(".f-ai-c-site-settings select")
    assert_no_selector(".f-ai-c-site-settings textarea")
  end

  test "keeps unavailable saved provider selected" do
    site = build(:folio_site,
                 ai_settings: {
                   "provider" => "openai",
                 })

    render_component(site, providers: { dummy: Folio::Ai::Providers::Dummy })

    assert_selector("select[name$='[ai_settings][provider]'] option[value='openai'][selected]",
                    text: /OpenAI/)
    assert_selector("select[name$='[ai_settings][provider]'] option[value='dummy']",
                    text: "Dummy")
    assert_selector("select[name$='[ai_settings][model]'] option[value=''][selected]",
                    text: /#{Folio::Ai::Providers::OpenAi.default_model}/)
    assert_selector(".f-ai-c-site-settings .f-c-ui-alert--warning", text: /OpenAI/)
  end

  test "resolves missing labels in the current locale" do
    I18n.with_locale(:cs) do
      render_component(build(:folio_site))
    end

    assert_text("Název stránky")
  end

  test "does not render when AI config is disabled" do
    Folio::Ai.config.stub(:enabled?, false) do
      render_component(build(:folio_site))
    end

    assert_no_selector(".f-ai-c-site-settings")
  end

  test "selects default option when saved model is not in provider list" do
    site = build(:folio_site,
                 ai_settings: {
                   "provider" => "dummy",
                   "model" => "custom-dummy",
                 })

    render_component(site)

    assert_selector("select[name$='[ai_settings][model]'] option[value=''][selected]",
                    text: /dummy/)
    assert_no_selector("select[name$='[ai_settings][model]'] option[value='custom-dummy']")
  end

  test "renders non-default model options from the selected provider" do
    site = build(:folio_site,
                 ai_settings: {
                   "provider" => "openai",
                 })

    Folio::Ai::Providers::OpenAi.stub(:models_env_value, "gpt-5.5,gpt-5.5-pro") do
      render_component(site, providers: { openai: Folio::Ai::Providers::OpenAi })
    end

    assert_selector("select[name$='[ai_settings][model]'] option[value=''][selected]",
                    text: /gpt-5.5/)
    assert_no_selector("select[name$='[ai_settings][model]'] option[value='gpt-5.5']")
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

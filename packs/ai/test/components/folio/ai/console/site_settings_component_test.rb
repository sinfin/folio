# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Console::SiteSettingsComponentTest < Folio::Console::ComponentTest
  setup do
    @original_rails_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    stub_request(:get, "https://api.openai.com/v1/models")
      .to_return(body: {
        data: [
          { id: "gpt-5.5", created: 1 },
        ],
      }.to_json)

    Folio::Ai.reset_registry!
    Folio::Ai.register_integration(key: :articles,
                                   record_class_name: "Dummy::Blog::Article",
                                   fields: [
                                     Folio::Ai::Field.new(key: :title,
                                                          character_limit: 120),
                                   ])
  end

  teardown do
    Rails.cache = @original_rails_cache
    Folio::Ai.reset_registry!
  end

  def render_component(site,
                       provider_api_key_env_values: { openai: "secret" },
                       provider_models_env_values: {},
                       **ai_config)
    with_ai_config(**{ enabled: true }.merge(ai_config)) do
      Folio::Ai.config.stub(:provider_api_key_env_values, provider_api_key_env_values) do
        Folio::Ai.config.stub(:provider_models_env_values, provider_models_env_values) do
          vc_test_controller.view_context.simple_form_for(site, url: "/") do |form|
            render_inline(Folio::Ai::Console::SiteSettingsComponent.new(form:))
          end
        end
      end
    end
  end

  def test_render
    site = build(:folio_site, ai_settings: {
                   enabled: true,
                   integrations: {
                     articles: {
                       fields: {
                         title: {
                           prompt: "Write a title.",
                         },
                       },
                     },
                 },
                 })

    render_component(site)

    assert_selector(".f-ai-c-site-settings")
    assert_no_selector(".form-switch")
    assert_text(Dummy::Blog::Article.model_name.human(count: 2))
    assert_text(Dummy::Blog::Article.human_attribute_name(:title))
    assert_selector("input[name$='[ai_settings][enabled]'][value='1']", visible: :all)
    assert_selector("select[name$='[ai_settings][default_provider]'] option[value='openai']", text: "OpenAI")
    assert_no_selector("select[name$='[ai_settings][default_provider]'] option", text: "Openai")
    assert_selector("select[name$='[ai_settings][default_model]']")
    assert_selector("textarea[name$='[fields][title][prompt]']", text: "Write a title.")
    assert_text("Limit: 120")
  end

  def test_render_does_not_fetch_provider_models
    site = build(:folio_site)

    render_component(site)

    assert_not_requested :get, "https://api.openai.com/v1/models"
  end

  def test_render_hides_provider_without_credentials
    site = build(:folio_site)

    render_component(site,
                     provider_api_key_env_values: {},
                     default_provider: :openai,
                     provider_models: {
                       openai: "gpt-5.5",
                       demo: "demo",
                     })

    assert_no_selector("select[name$='[ai_settings][default_provider]'] option[value='openai']")
    assert_selector("select[name$='[ai_settings][default_provider]'] option[value='demo']", text: "Demo")
  end

  def test_render_shows_anthropic_with_credentials
    site = build(:folio_site)

    render_component(site,
                     provider_api_key_env_values: {
                       openai: "secret",
                       anthropic: "secret",
                     })

    assert_selector("select[name$='[ai_settings][default_provider]'] option[value='anthropic']",
                    text: "Anthropic")
  end

  def test_render_disables_settings_without_eligible_providers
    site = build(:folio_site, ai_settings: { enabled: true })

    I18n.with_locale(:en) do
      render_component(site, provider_api_key_env_values: {})
    end

    assert_selector(".f-ai-c-site-settings__intro.alert-danger",
                    text: "Configure AI provider credentials before editing AI suggestions settings for this site.")
    assert_no_selector(".f-ai-c-site-settings input", visible: :all)
    assert_no_selector(".f-ai-c-site-settings select", visible: :all)
    assert_no_selector(".f-ai-c-site-settings textarea", visible: :all)
    assert_no_selector(".f-ai-c-site-settings__integration")
  end

  def test_render_ignores_saved_ineligible_provider_overrides
    site = build(:folio_site, ai_settings: {
                   default_provider: "openai",
                   default_model: "gpt-5.5",
                   integrations: {
                     articles: {
                       default_provider: "openai",
                       default_model: "gpt-5.5",
                       fields: {
                         title: {
                           provider: "openai",
                           model: "gpt-5.5",
                         },
                       },
                     },
                   },
                 })

    render_component(site,
                     provider_api_key_env_values: {},
                     default_provider: :openai,
                     provider_models: {
                       openai: "gpt-5.5",
                       demo: "demo",
                     })

    assert_no_selector("select option[value='openai']")
    assert_selector("select[name$='[ai_settings][default_provider]'] option[value='demo'][selected]")
    assert_selector("select[name$='[ai_settings][default_model]'] option[value=''][selected]")
    assert_selector("select[name$='[ai_settings][integrations][articles][default_provider]'] option[value='']")
    assert_selector("select[name$='[ai_settings][integrations][articles][fields][title][provider]'] option[value='']")
  end

  def test_render_uses_env_model_options
    site = build(:folio_site)

    render_component(site, provider_models_env_values: { openai: "gpt-5.5-pro" })

    assert_selector("select[name$='[ai_settings][default_model]'] option[value='gpt-5.4-mini']")
    assert_selector("select[name$='[ai_settings][default_model]'] option[value='gpt-5.5']")
    assert_selector("select[name$='[ai_settings][default_model]'] option[value='gpt-5.5-pro']")
  end

  def test_provider_options_fall_back_to_humanized_label
    site = build(:folio_site)

    render_component(site, provider_models: {
                       openai: "gpt-5.5",
                       custom_provider: "custom-model",
                     })

    assert_selector("select[name$='[ai_settings][default_provider]'] option[value='custom_provider']",
                    text: "Custom provider")
  end

  def test_english_default_labels_do_not_use_inherit_wording
    site = build(:folio_site)

    I18n.with_locale(:en) do
      render_component(site)
    end

    assert_selector("option[value='']", text: "Default")
    assert_no_text("Inherit")
  end

  def test_czech_default_labels_do_not_use_inherit_wording
    site = build(:folio_site)

    I18n.with_locale(:cs) do
      render_component(site)
    end

    assert_selector("option[value='']", text: "Výchozí")
    assert_no_text("Dědit")
  end

  def test_does_not_render_when_ai_is_disabled
    site = build(:folio_site)

    with_ai_config(enabled: false) do
      vc_test_controller.view_context.simple_form_for(site, url: "/") do |form|
        render_inline(Folio::Ai::Console::SiteSettingsComponent.new(form:))
      end
    end

    assert_no_selector(".f-ai-c-site-settings")
  end
end

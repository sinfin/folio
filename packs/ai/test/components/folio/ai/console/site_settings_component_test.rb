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

  def render_component(site, **ai_config)
    with_ai_config(**{ enabled: true }.merge(ai_config)) do
      vc_test_controller.view_context.simple_form_for(site, url: "/") do |form|
        render_inline(Folio::Ai::Console::SiteSettingsComponent.new(form:))
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

  def test_provider_options_fall_back_to_humanized_label
    site = build(:folio_site)

    render_component(site, provider_models: {
                       openai: "gpt-5.5",
                       custom_provider: "custom-model",
                     })

    assert_selector("select[name$='[ai_settings][default_provider]'] option[value='custom_provider']",
                    text: "Custom provider")
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

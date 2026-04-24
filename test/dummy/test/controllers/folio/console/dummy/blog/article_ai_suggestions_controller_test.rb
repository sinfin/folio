# frozen_string_literal: true

require "test_helper"

class Folio::Console::Dummy::Blog::ArticleAiSuggestionsControllerTest < Folio::Console::BaseControllerTest
  def setup
    super

    Folio::Ai.reset_registry!
    register_dummy_ai_integration

    @site.update!(ai_settings: enabled_ai_settings)
    @article = create(:dummy_blog_article, site: @site)
  end

  def teardown
    Folio::Ai.reset_registry!

    super
  end

  test "returns demo suggestions through the reusable endpoint contract" do
    with_config(folio_ai_enabled: true) do
      post console_dummy_blog_article_ai_suggestions_path(@article),
           params: request_params(field_key: :title),
           as: :json
    end

    json = JSON.parse(response.body)

    assert_response :success
    assert_equal "Demo AI headline focused on the main editorial hook",
                 json.dig("data", "suggestions", 0, "text")
    assert_equal "Neutral", json.dig("data", "suggestions", 0, "meta", "tone_label")
    assert_equal "openai", json.dig("data", "provider")
    assert_equal "gpt-5.5", json.dig("data", "model")
  end

  test "persists editor instructions when regenerate asks for persistence" do
    with_config(folio_ai_enabled: true) do
      post console_dummy_blog_article_ai_suggestions_path(@article),
           params: request_params(field_key: :perex,
                                  instructions: "Use a calmer voice.",
                                  persist_instructions: "1"),
           as: :json
    end

    instruction = Folio::Ai::UserInstruction.find_or_initialize_for(user: @superadmin,
                                                                    site: @site,
                                                                    integration_key: :dummy_blog_articles,
                                                                    field_key: :perex)

    assert_response :success
    assert_equal "Use a calmer voice.", instruction.instruction
  end

  test "returns prompt_missing when the site prompt is blank" do
    @site.update!(ai_settings: enabled_ai_settings(prompt: ""))

    with_config(folio_ai_enabled: true) do
      post console_dummy_blog_article_ai_suggestions_path(@article),
           params: request_params(field_key: :title),
           as: :json
    end

    json = JSON.parse(response.body)

    assert_response :unprocessable_entity
    assert_equal "prompt_missing", json["error_code"]
  end

  test "returns host_ineligible when the dummy article has no source text" do
    @article.update_columns(title: "", perex: "")

    with_config(folio_ai_enabled: true) do
      post console_dummy_blog_article_ai_suggestions_path(@article),
           params: request_params(field_key: :title),
           as: :json
    end

    json = JSON.parse(response.body)

    assert_response :unprocessable_entity
    assert_equal "host_ineligible", json["error_code"]
  end

  private
    def register_dummy_ai_integration
      Folio::Ai.register_integration(:dummy_blog_articles,
                                     label: "Dummy blog articles",
                                     fields: ai_fields)
    end

    def ai_fields
      [
        ai_field(:title, input_types: %i[string], character_limit: 120),
        ai_field(:perex, input_types: %i[text], character_limit: 400),
        ai_field(:meta_title, input_types: %i[string], character_limit: 120),
        ai_field(:meta_description, input_types: %i[text], character_limit: 400),
      ]
    end

    def ai_field(key, **options)
      Folio::Ai::Field.new(key:,
                           auto_attach: true,
                           **options)
    end

    def request_params(field_key:, instructions: "", persist_instructions: "0")
      {
        integration_key: "dummy_blog_articles",
        field_key: field_key.to_s,
        instructions:,
        persist_instructions:,
      }
    end

    def enabled_ai_settings(prompt: "Write a safe demo suggestion.")
      {
        enabled: true,
        integrations: {
          dummy_blog_articles: {
            fields: enabled_ai_fields(prompt:),
          },
        },
      }
    end

    def enabled_ai_fields(prompt:)
      %i[title perex meta_title meta_description].index_with do
        {
          enabled: true,
          prompt:,
        }
      end
    end
end

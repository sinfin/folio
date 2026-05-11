# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Console::Api::TextSuggestionsControllerTest < Folio::Console::BaseControllerTest
  class RaisingProviderAdapter
    def generate_suggestions(prompt:, field:, suggestion_count:)
      raise Folio::Ai::ProviderTimeoutError, "timeout"
    end
  end

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

  test "renders suggestions component json from the central pack endpoint" do
    with_ai_config(enabled: true) do
      get console_api_ai_text_suggestions_path,
          params: request_params(field_key: :title,
                                 show_meta: "1"),
          as: :json
    end

    page = Capybara.string(response_component_html)

    assert_response :success
    assert page.has_css?(".f-ai-c-text-suggestions")
    assert page.has_css?(".f-ai-c-text-suggestions__suggestion", text: "Demo AI headline focused on the main editorial hook")
    assert page.has_css?(".f-ai-c-text-suggestions__suggestion-meta", text: "Neutral")
  end

  test "persists editor instructions through the instructions endpoint" do
    with_ai_config(enabled: true) do
      post instructions_console_api_ai_text_suggestions_path,
           params: request_params(field_key: :perex,
                                  instructions: "Use a calmer voice."),
           as: :json
    end

    instruction = Folio::Ai::UserInstruction.find_or_initialize_for(user: @superadmin,
                                                                    site: @site,
                                                                    integration_key: :dummy_blog_articles,
                                                                    field_key: :perex)

    assert_response :success
    assert_equal "Use a calmer voice.", instruction.instruction
    assert_includes response_component_html, "Alternative demo summary"
  end

  test "renders prompt_missing in component json" do
    @site.update!(ai_settings: enabled_ai_settings(prompt: ""))

    with_ai_config(enabled: true) do
      get console_api_ai_text_suggestions_path,
          params: request_params(field_key: :title),
          as: :json
    end

    assert_response :success
    assert_includes response_component_html, I18n.t("folio.ai.console.errors.prompt_missing")
  end

  test "renders host_ineligible in component json" do
    @article.update_columns(title: "", perex: "")

    with_ai_config(enabled: true) do
      get console_api_ai_text_suggestions_path,
          params: request_params(field_key: :title),
          as: :json
    end

    assert_response :success
    assert_includes response_component_html, I18n.t("folio.ai.console.errors.host_ineligible")
  end

  test "renders invalid_context when model contract is missing" do
    page = create(:folio_page, site: @site)
    Folio::Ai.reset_registry!
    Folio::Ai.register_integration(:folio_pages, fields: [Folio::Ai::Field.new(key: :title)])
    @site.update!(ai_settings: enabled_ai_settings(integration_key: :folio_pages,
                                                  field_keys: %i[title]))

    with_ai_config(enabled: true) do
      get console_api_ai_text_suggestions_path,
          params: request_params(record: page,
                                 integration_key: :folio_pages,
                                 field_key: :title),
          as: :json
    end

    assert_response :success
    assert_includes response_component_html, I18n.t("folio.ai.console.errors.invalid_context")
  end

  test "renders record_not_ready when record is not accessible on the current site" do
    other_site = create_site(force: true)
    other_article = create(:dummy_blog_article, site: other_site)

    with_ai_config(enabled: true) do
      get console_api_ai_text_suggestions_path,
          params: request_params(record: other_article,
                                 field_key: :title),
          as: :json
    end

    assert_response :success
    assert_includes response_component_html, I18n.t("folio.ai.console.errors.record_not_ready")
  end

  test "renders provider timeout in component json" do
    Dummy::Blog::Article.stub(:folio_ai_demo_provider_adapter_class, RaisingProviderAdapter) do
      with_ai_config(enabled: true) do
        get console_api_ai_text_suggestions_path,
            params: request_params(field_key: :title),
            as: :json
      end
    end

    assert_response :success
    assert_includes response_component_html, I18n.t("folio.ai.console.errors.provider_timeout")
  end

  private
    def response_component_html
      response.parsed_body["data"]
    end

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
                           **options)
    end

    def request_params(record: @article, integration_key: :dummy_blog_articles, field_key:, instructions: nil, show_meta: nil)
      {
        klass: record.class.name,
        id: record.id,
        integration_key: integration_key.to_s,
        field_key: field_key.to_s,
        component_id: "ai_#{field_key}",
        instructions:,
        show_meta:,
      }.compact
    end

    def enabled_ai_settings(integration_key: :dummy_blog_articles,
                            field_keys: %i[title perex meta_title meta_description],
                            prompt: "Write a safe demo suggestion.")
      {
        enabled: true,
        integrations: {
          integration_key => {
            fields: enabled_ai_fields(field_keys:, prompt:),
          },
        },
      }
    end

    def enabled_ai_fields(field_keys:, prompt:)
      field_keys.index_with do
        {
          enabled: true,
          prompt:,
        }
      end
    end
end

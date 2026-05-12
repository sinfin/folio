# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Console::Api::TextSuggestionsControllerTest < Folio::Console::BaseControllerTest
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

  test "renders loading component json and enqueues text suggestions job" do
    with_ai_config(enabled: true) do
      assert_enqueued_jobs 1, only: Folio::Ai::TextSuggestionsJob do
        post text_suggestions_console_api_ai_text_suggestions_path,
             params: request_params(field_key: :title,
                                    show_meta: "1"),
             as: :json
      end
    end

    page = Capybara.string(response_component_html)

    assert_response :success
    assert page.has_css?(".f-ai-c-text-suggestions")
    assert page.has_no_css?(".f-ai-c-text-suggestions--loading")
    assert page.has_css?(".f-ai-c-text-suggestions__suggestion--loading", count: 3)
    assert page.has_css?(".f-ai-c-text-suggestions__suggestion-loader.folio-loader", count: 3)
    assert page.has_no_css?(".f-ai-c-text-suggestions__loader")
    assert response.parsed_body.dig("meta", "request_id").present?
    assert page.has_css?("[data-action*='f-ai-input:suggestionStale->f-ai-c-text-suggestions#clearSuggestionSelection']")
    assert page.has_no_css?("[data-f-ai-c-text-suggestions-target='suggestion']")

    job_params = enqueued_text_suggestions_job_arguments[:params].with_indifferent_access
    assert_not job_params.key?(:klass)
    assert_not job_params.key?(:id)
    assert_equal true, job_params[:host_eligible]
    assert_equal "Dummy::Ai::DemoProviderAdapter", job_params[:provider_adapter_class_name]
    assert_includes job_params[:context].keys.map(&:to_s), "title"
  end

  test "persists editor instructions before enqueueing instructions job" do
    with_ai_config(enabled: true) do
      assert_enqueued_jobs 1, only: Folio::Ai::TextSuggestionsJob do
        post instructions_console_api_ai_text_suggestions_path,
             params: request_params(field_key: :perex,
                                    instructions: "Use a calmer voice."),
             as: :json
      end
    end

    instruction = Folio::Ai::UserInstruction.find_or_initialize_for(user: @superadmin,
                                                                    site: @site,
                                                                    integration_key: :dummy_blog_articles,
                                                                    field_key: :perex)

    assert_response :success
    assert_equal "Use a calmer voice.", instruction.instruction
    assert_not_includes response_component_html, "Alternative demo summary"
  end

  test "requires message bus client id" do
    with_ai_config(enabled: true) do
      assert_no_enqueued_jobs only: Folio::Ai::TextSuggestionsJob do
        post text_suggestions_console_api_ai_text_suggestions_path,
             params: request_params(field_key: :title).except(:message_bus_client_id),
             as: :json
      end
    end

    assert_response :unprocessable_entity
    assert_equal "message_bus_client_id is required", response.parsed_body["errors"].first["title"]
  end

  private
    def response_component_html
      response.parsed_body["data"]
    end

    def enqueued_text_suggestions_job_arguments
      job = enqueued_jobs.reverse.find { |enqueued_job| enqueued_job[:job] == Folio::Ai::TextSuggestionsJob }
      args = job[:args]
      args = ActiveJob::Arguments.deserialize(args) if args.first.is_a?(Hash) && args.first.key?("_aj_symbol_keys")

      args.first.with_indifferent_access
    end

    def register_dummy_ai_integration
      Folio::Ai.register_integration(record_class_name: "Dummy::Blog::Article",
                                     fields: ai_fields)
    end

    def ai_fields
      [
        ai_field(:title, character_limit: 120),
        ai_field(:perex, character_limit: 400),
        ai_field(:meta_title, character_limit: 120),
        ai_field(:meta_description, character_limit: 400),
      ]
    end

    def ai_field(key, **options)
      Folio::Ai::Field.new(key:,
                           **options)
    end

    def request_params(record: @article,
                       integration_key: :dummy_blog_articles,
                       field_key:,
                       instructions: nil,
                       show_meta: nil,
                       current_form_snapshot_json: nil)
      {
        klass: record.class.name,
        id: record.id,
        integration_key: integration_key.to_s,
        field_key: field_key.to_s,
        component_id: "ai_#{field_key}",
        instructions:,
        show_meta:,
        message_bus_client_id: "message-bus-client",
        current_form_snapshot_json:,
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

# frozen_string_literal: true

require "test_helper"

class Folio::Ai::TextSuggestionsJobTest < ActiveJob::TestCase
  class RaisingProviderAdapter
    def generate_suggestions(prompt:, field:, suggestion_count:)
      raise Folio::Ai::ProviderTimeoutError, "timeout"
    end
  end

  class CapturingProviderAdapter
    attr_reader :calls

    def initialize
      @calls = []
    end

    def generate_suggestions(prompt:, field:, suggestion_count:)
      calls << {
        prompt:,
        field:,
        suggestion_count:,
      }

      [
        Folio::Ai::Suggestion.new(key: 1, text: "Fallback snapshot suggestion"),
      ]
    end
  end

  setup do
    Folio::Ai.reset_registry!
    register_dummy_ai_integration

    @site = create_site(force: true)
    @site.update!(ai_settings: enabled_ai_settings)
    @user = create(:folio_user, :superadmin)
    @article = create(:dummy_blog_article, site: @site)
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "broadcasts rendered suggestions to the message bus client" do
    message = perform_text_suggestions_job

    assert_equal Folio::MESSAGE_BUS_CHANNEL, message[:channel]
    assert_equal({ client_ids: ["message-bus-client"] }, message[:options])
    assert_equal "Folio::Ai::TextSuggestionsJob", message[:payload]["type"]
    assert_equal "request-hash", message[:payload]["data"]["request_id"]
    assert_equal "ai_title", message[:payload]["data"]["component_id"]
    assert_includes message[:payload]["data"]["html"], "Demo AI headline focused on the main editorial hook"
    assert_includes message[:payload]["data"]["html"], "Neutral"
  end

  test "broadcasts prompt_missing in rendered component html" do
    @site.update!(ai_settings: enabled_ai_settings(prompt: ""))

    message = perform_text_suggestions_job

    assert_includes message[:payload]["data"]["html"], I18n.t("folio.ai.console.errors.prompt_missing")
  end

  test "broadcasts host_ineligible in rendered component html" do
    message = perform_text_suggestions_job(params: job_params(host_eligible: false))

    assert_includes message[:payload]["data"]["html"], I18n.t("folio.ai.console.errors.host_ineligible_article")
  end

  test "uses fallback form snapshot context when model hooks are missing" do
    adapter = CapturingProviderAdapter.new
    provider_factory = ->(**) { adapter }

    Folio::Ai.reset_registry!
    Folio::Ai.register_integration(record_class_name: "Folio::Page",
                                   fields: [Folio::Ai::Field.new(key: :title)])
    @site.update!(ai_settings: enabled_ai_settings(integration_key: :folio_pages,
                                                  field_keys: %i[title]))

    Folio::Ai.stub(:provider_adapter, provider_factory) do
      message = perform_text_suggestions_job(params: job_params(integration_key: :folio_pages,
                                                                field_key: :title,
                                                                context: {
                                                                  current_form_snapshot: {
                                                                    "page[title]" => "Unsaved title",
                                                                  },
                                                                },
                                                                provider_adapter_class_name: nil))

      assert_includes message[:payload]["data"]["html"], "Fallback snapshot suggestion"
    end

    assert_equal 1, adapter.calls.length
    assert_includes adapter.calls.first[:prompt], '"current_form_snapshot": {'
    assert_includes adapter.calls.first[:prompt], '"page[title]": "Unsaved title"'
  end

  test "broadcasts record_not_ready when record is not accessible on the current site" do
    message = perform_text_suggestions_job(params: job_params(error_code: :record_not_ready))

    assert_includes message[:payload]["data"]["html"], I18n.t("folio.ai.console.errors.record_not_ready")
  end

  test "broadcasts provider timeout in rendered component html" do
    message = perform_text_suggestions_job(params: job_params(provider_adapter_class_name: RaisingProviderAdapter.name))

    assert_includes message[:payload]["data"]["html"], I18n.t("folio.ai.console.errors.provider_timeout")
  end

  test "does not mutate Folio current state" do
    current_user = create(:folio_user)
    Folio::Current.user = current_user

    perform_text_suggestions_job

    assert_equal current_user, Folio::Current.user
  ensure
    Folio::Current.reset
  end

  private
    def perform_text_suggestions_job(params: job_params)
      messages = capture_message_bus do
        with_ai_config(enabled: true,
                       default_provider: :demo,
                       provider_models: { demo: "demo" }) do
          Folio::Ai::TextSuggestionsJob.perform_now(request_id: "request-hash",
                                                    message_bus_client_id: "message-bus-client",
                                                    user_id: @user.id,
                                                    site_id: @site.id,
                                                    params:)
        end
      end

      messages.fetch(0)
    end

    def capture_message_bus(&block)
      messages = []
      publisher = lambda do |channel, payload, **options|
        messages << {
          channel:,
          payload: JSON.parse(payload),
          options:,
        }
      end

      MessageBus.stub(:publish, publisher, &block)

      messages
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

    def job_params(integration_key: :dummy_blog_articles,
                   field_key: :title,
                   instructions: nil,
                   show_meta: "1",
                   context: article_context,
                   host_eligible: true,
                   provider_adapter_class_name: "Dummy::Ai::DemoProviderAdapter",
                   error_code: nil)
      {
        integration_key: integration_key.to_s,
        field_key: field_key.to_s,
        component_id: "ai_#{field_key}",
        field_label: field_key.to_s.humanize,
        instructions:,
        show_meta:,
        suggestion_count: 3,
        context:,
        host_eligible:,
        provider_adapter_class_name:,
        error_code:,
      }.compact
    end

    def article_context
      {
        title: @article.title,
        perex: @article.perex,
      }
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

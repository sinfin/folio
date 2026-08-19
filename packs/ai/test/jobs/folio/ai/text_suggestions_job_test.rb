# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::TextSuggestionsJobTest < ActiveJob::TestCase
  setup do
    Folio::Ai.reset_registry!
    register_dummy_ai_integration
    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern

    @site = create_site(force: true)
    @site = create(Rails.application.config.folio_site_default_test_factory,
                   locale: "en",
                   ai_settings: enabled_ai_settings)
    @user = create(:folio_user, :superadmin)
    @article = create(:dummy_blog_article, site: @site)
    @page = create(:folio_page, site: @site)
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "broadcasts rendered provider errors" do
    provider = Object.new
    provider.define_singleton_method(:complete) do |prompt:, suggestion_count:|
      raise Folio::Ai::ProviderError, "failed"
    end

    message = perform_text_suggestions_job(provider: provider).first

    assert_equal "en", @site.locale
    assert_includes message[:payload].dig("data", "html"), "AI suggestions could not be generated."
  end

  test "renders provider errors in the site console locale" do
    @site.update!(locale: "cs")

    provider = Object.new
    provider.define_singleton_method(:complete) do |prompt:, suggestion_count:|
      raise Folio::Ai::ProviderError, "failed"
    end

    message = perform_text_suggestions_job(provider: provider).first

    assert_not_includes message[:payload].dig("data", "html"), "AI suggestions could not be generated."
    assert_includes message[:payload].dig("data", "html"), "AI návrhy se nepodařilo vygenerovat."
  end


  test "broadcasts rendered suggestion fragment to message bus client" do
    message = Folio::Ai::Providers::Dummy.stub(:available?, true) do
      perform_text_suggestions_job().first
    end

    assert_equal Folio::MESSAGE_BUS_CHANNEL, message[:channel]
    assert_equal({ client_ids: ["client-1"] }, message[:options])
    assert_equal "Folio::Ai::TextSuggestionsJob", message[:payload]["type"]
    assert_equal "request-1", message[:payload].dig("data", "request_id")
    assert_equal "ai_title", message[:payload].dig("data", "component_id")
    assert_includes message[:payload].dig("data", "html"), "Dummy title for testing AI suggestions"
    assert_includes message[:payload].dig("data", "fragments", "ai_title"), "Dummy title for testing AI suggestions"
    assert_not_includes message[:payload].dig("data", "html"), "Return only valid JSON"
  end

  test "broadcasts grouped child fragments" do
    provider = GroupedCapturingProvider.new

    params = job_params.merge(grouped: true,
                              key: "meta",
                              component_id: "ai_group",
                              fields: [
                                { key: "title", label: "Title", component_id: "ai_title" },
                                { key: "perex", label: "Perex", component_id: "ai_perex" },
                              ])
    message = perform_text_suggestions_job(provider: provider, params:).first

    assert_equal 1, provider.calls
    assert_equal Folio::Ai::GROUPED_SUGGESTION_COUNT, provider.suggestion_count
    assert_equal true, message[:payload].dig("data", "grouped")
    assert_equal "ai_group", message[:payload].dig("data", "component_id")

    title_fragment = message[:payload].dig("data", "fragments", "ai_title")
    assert_includes title_fragment, "f-ai-c-text-suggestions--grouped"
    assert_includes title_fragment, "Grouped title"
    assert_not_includes title_fragment, "f-ai-c-text-suggestions__close"
    assert_not_includes title_fragment, "f-ai-c-text-suggestions__instructions"
    assert_includes message[:payload].dig("data", "fragments", "ai_perex"),
                    "Grouped perex"
  end


  test "passes site prompt and user instructions to provider" do
    provider = CapturingProvider.new

    perform_text_suggestions_job(provider:)

    assert_includes provider.prompt, "Write a title from the site prompt."
    assert_includes provider.prompt, "Be direct."
  end

  test "passes capped suggestion count to provider" do
    provider = CapturingProvider.new

    perform_text_suggestions_job(provider:, params: job_params.merge(suggestion_count: 99))

    assert_equal Folio::Ai::MAX_SUGGESTION_COUNT, provider.suggestion_count
  end

  test "broadcasts prompt_missing in rendered component html" do
    @site.update!(ai_settings: enabled_ai_settings(prompt: ""))

    message = perform_text_suggestions_job.first

    # assert_includes message[:payload]["data"]["html"], I18n.t("folio.ai.console.errors.prompt_missing", locale: @site.console_locale)
    assert_includes message[:payload]["data"]["html"], "AI suggestions could not be generated."
  end

  test "broadcasts host_ineligible in rendered component html" do
    message = perform_text_suggestions_job(params: job_params.merge({ host_eligible: false })).first

    # assert_includes message[:payload]["data"]["html"], I18n.t("folio.ai.console.errors.host_ineligible_article", locale: @site.console_locale)
    assert_includes message[:payload]["data"]["html"], "AI suggestions could not be generated."
  end

  test "uses fallback form snapshot when model hooks are missing" do
    provider = MonitoringProvider.new
    @site.update!(ai_settings: enabled_ai_settings(integration_key: :folio_pages,
                                                  field_keys: %i[title]))
    params = job_params.merge({ integration_key: :folio_pages,
                                field_key: :title,
                                form_snapshot: {
                                  "title" => "Unsaved title",
                                }
                              })

    message = perform_text_suggestions_job(provider:, params:).first

    assert_includes message[:payload]["data"]["html"], "Fallback snapshot suggestion"

    assert_equal 1, provider.calls.length
    assert_includes provider.calls.first[:prompt], '"form_snapshot": {'
    assert_includes provider.calls.first[:prompt], '"title": "Unsaved title"'
  end

  test "broadcasts record_not_ready when record is not accessible on the current site" do
    message = perform_text_suggestions_job(params: job_params.merge({ error_code: :record_not_ready })).first

    # assert_includes message[:payload]["data"]["html"], I18n.t("folio.ai.console.errors.record_not_ready", locale: @site.console_locale)
    assert_includes message[:payload]["data"]["html"], "AI suggestions could not be generated."
  end

  test "broadcasts provider timeout in rendered component html" do
    provider = RaisingProvider.new(Folio::Ai::ProviderError.new("timeout"))
    message = perform_text_suggestions_job(provider:, params: job_params).first

    assert_includes message[:payload]["data"]["html"], "AI suggestions could not be generated."
  end

  test "logs unexpected failures without exception messages" do
    logged_messages = []
    logger = Object.new
    logger.define_singleton_method(:warn) { |message| logged_messages << message }

    provider = RaisingProvider.new(Folio::Ai::ProviderError.new("SECRET_PROMPT_BODY"))

    Rails.stub(:logger, logger) do
      message = perform_text_suggestions_job(params: job_params, provider:).first

      assert_includes message[:payload]["data"]["html"], "AI suggestions could not be generated."
    end

    assert_equal 1, logged_messages.length
    assert_includes logged_messages.first, "error_class=Folio::Ai::ProviderError"
    assert_includes logged_messages.first, "request_id=request-1"
    assert_includes logged_messages.first, "record_key=folio_pages"
    assert_includes logged_messages.first, "field_key=title"
    assert_not_includes logged_messages.first, "SECRET_PROMPT_BODY"
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
    def perform_text_suggestions_job(provider: nil, params: job_params)
      messages = capture_message_bus do
        I18n.with_locale(@site.locale) do
          if provider.present?
            Folio::Ai.stub(:provider_for, provider) do
              Folio::Ai::TextSuggestionsJob.perform_now(request_id: "request-1",
                                                        params:)
            end
          else
            Folio::Ai::TextSuggestionsJob.perform_now(request_id: "request-1",
                                                      params:)
          end
        end
      end

      messages
    end

    def register_dummy_ai_integration
      Folio::Ai.register_record(record_class_name: "Dummy::Blog::Article",
                                    fields: ai_article_fields)
      Folio::Ai.register_record(record_class_name: "Folio::Page",
                                    fields: [
                                      { key: :title, character_limit: 80 },
                                      { key: :perex, character_limit: 400 },
                                    ])
    end

    def enabled_ai_settings(integration_key: :dummy_blog_articles,
                            field_keys: %i[title perex meta_title meta_description],
                            prompt: "Write a safe demo suggestion.")
      {
        enabled: true,
        provider: "dummy",
        integrations: {
          integration_key => {
            fields: enabled_ai_fields(field_keys:, prompt:),
          },
        },
      }
    end


    def job_params
      {
        klass: "Folio::Page",
        id: @page.id,
        key: "title",
        grouped: false,
        message_bus_client_id: "client-1",
        component_id: "ai_title",
        form_snapshot: { "title" => "Draft title" },
        site_prompt: "Write a title from the site prompt.",
        instructions: "Be direct.",
        suggestion_count: 3,
        record_key: "folio_pages",
        field: {
          key: "title",
          label: "Title",
          character_limit: 80,
        },
        site_id: @site.id,
        user_id: @user.id,
      }
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

    def enabled_ai_fields(field_keys:, prompt:)
      field_keys.index_with do
        {
          enabled: true,
          prompt:,
        }
      end
    end

    def ai_article_fields
      [
        { key: :title, character_limit: 120 },
        { key: :perex, character_limit: 400 },
        { key: :meta_title, character_limit: 120 },
        { key: :meta_description, character_limit: 400 },
      ]
    end

    class CapturingProvider
      attr_reader :prompt,
                  :suggestion_count

      def complete(prompt:, suggestion_count:)
        @prompt = prompt
        @suggestion_count = suggestion_count
        {
          suggestions: [
            { key: "title", text: "Provider title" },
          ],
        }.to_json
      end
    end

    class GroupedCapturingProvider
      attr_reader :prompt,
                  :suggestion_count,
                  :calls

      def initialize
        @calls = 0
      end

      def complete(prompt:, suggestion_count:)
        @calls += 1
        @prompt = prompt
        @suggestion_count = suggestion_count
        {
          suggestions: [
            { key: "title", text: "Grouped title" },
            { key: "perex", text: "Grouped perex" },
          ],
        }.to_json
      end
    end

    class RaisingProvider
      attr_reader :exception
      def initialize(exception)
        @exception = exception
      end

      def complete(prompt:, suggestion_count:)
        raise exception
      end
    end

    class MonitoringProvider
      attr_reader :calls

      def initialize
        @calls = []
      end


      def complete(prompt:, suggestion_count:)
        calls << {
          prompt:,
          suggestion_count:,
          fields: prompt_data(prompt)["fields"],
        }

        {
          suggestions: [
            { key: :title, text: "Fallback snapshot suggestion" },
          ],
        }.to_json
      end

      def prompt_data(prompt)
        JSON.parse(prompt.to_s.split(Folio::Ai::TextSuggestionGenerator::CONTEXT_MARKER, 2).last.to_s)
      rescue JSON::ParserError
        {}
      end
    end
end

# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::TextSuggestionsJobTest < ActiveJob::TestCase
  setup do
    Folio::Ai.reset_registry!
    Folio::Ai.register_record(record_class_name: "Folio::Page",
                              fields: [
                                { key: :title, character_limit: 80 },
                                { key: :perex, character_limit: 400 },
                              ])
    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern

    @site = create(Rails.application.config.folio_site_default_test_factory,
                   ai_settings: { "enabled" => true, "provider" => "dummy" })
    @page = create(:folio_page, site: @site)
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "broadcasts rendered suggestion fragment to message bus client" do
    message = capture_message do
      I18n.with_locale(:en) do
        Folio::Ai::Providers::Dummy.stub(:available?, true) do
          perform_job
        end
      end
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
    message = capture_message do
      I18n.with_locale(:en) do
        Folio::Ai::Providers::Dummy.stub(:available?, true) do
          perform_job(job_params.merge(grouped: true,
                                       key: "meta",
                                       component_id: "ai_group",
                                       fields: [
                                         { key: "title", label: "Title", component_id: "ai_title" },
                                         { key: "perex", label: "Perex", component_id: "ai_perex" },
                                       ]))
        end
      end
    end

    assert_equal true, message[:payload].dig("data", "grouped")
    assert_equal "ai_group", message[:payload].dig("data", "component_id")

    title_fragment = message[:payload].dig("data", "fragments", "ai_title")
    assert_includes title_fragment, "f-ai-c-text-suggestions--grouped"
    assert_includes title_fragment, "Dummy title for testing AI suggestions"
    assert_not_includes title_fragment, "f-ai-c-text-suggestions__close"
    assert_not_includes title_fragment, "f-ai-c-text-suggestions__instructions"
    assert_includes message[:payload].dig("data", "fragments", "ai_perex"),
                    "Dummy perex summarizing the article angle"
  end

  test "broadcasts rendered provider errors" do
    provider = Object.new
    provider.define_singleton_method(:complete) do |prompt:, suggestion_count:|
      raise Folio::Ai::ProviderError, "failed"
    end

    message = capture_message do
      I18n.with_locale(:en) do
        Folio::Ai.stub(:provider_for, provider) do
          perform_job
        end
      end
    end

    assert_includes message[:payload].dig("data", "html"), "AI suggestions could not be generated."
  end

  test "passes site prompt and user instructions to provider" do
    provider = CapturingProvider.new

    capture_message do
      I18n.with_locale(:en) do
        Folio::Ai.stub(:provider_for, provider) do
          perform_job
        end
      end
    end

    assert_includes provider.prompt, "Write a title from the site prompt."
    assert_includes provider.prompt, "Be direct."
  end

  private
    def perform_job(params = job_params)
      Folio::Ai::TextSuggestionsJob.perform_now(request_id: "request-1",
                                                params:)
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
      }
    end

    def capture_message(&block)
      messages = []

      MessageBus.stub(:publish, ->(channel, payload, **options) {
        messages << {
          channel:,
          payload: JSON.parse(payload),
          options:,
        }
      }, &block)

      messages.fetch(0)
    end

    class CapturingProvider
      attr_reader :prompt

      def complete(prompt:, suggestion_count:)
        @prompt = prompt
        {
          suggestions: [
            { text: "Provider title" },
          ],
        }.to_json
      end
    end
end

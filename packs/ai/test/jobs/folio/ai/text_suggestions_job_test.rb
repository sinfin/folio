# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::TextSuggestionsJobTest < ActiveJob::TestCase
  setup do
    Folio::Ai.reset_registry!
    Folio::Ai.register_record(record_class_name: "Folio::Page",
                              fields: [
                                { key: :title, character_limit: 80 },
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

  private
    def perform_job
      Folio::Ai::TextSuggestionsJob.perform_now(request_id: "request-1",
                                                params: job_params)
    end

    def job_params
      {
        klass: "Folio::Page",
        id: @page.id,
        key: "title",
        group: false,
        message_bus_client_id: "client-1",
        component_id: "ai_title",
        form_snapshot: { "folio_page[title]" => "Draft title" },
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
end

# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::Console::Api::TextSuggestionsControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  def setup
    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern
    Folio::User.include(Folio::Ai::UserConcern) unless Folio::User < Folio::Ai::UserConcern

    super

    Folio::Ai.reset_registry!
    Folio::Ai.register_record(record_class_name: "Folio::Page",
                              fields: [
                                { key: :title, character_limit: 80 },
                              ])

    @site.update!(ai_settings: { "enabled" => true, "provider" => "dummy" })
    @page = create(:folio_page, site: @site)
  end

  def teardown
    Folio::Ai.reset_registry!

    super
  end

  test "creates loading component response and enqueues job" do
    Folio::Ai::Providers::Dummy.stub(:available?, true) do
      assert_enqueued_jobs 1, only: Folio::Ai::TextSuggestionsJob do
        post console_api_ai_text_suggestions_path(format: :json),
             params: request_params(group: "1", instructions: "Keep it short."),
             as: :json
      end
    end

    assert_response :ok
    assert_includes response.parsed_body["data"], "f-ai-c-text-suggestions__suggestion--loading"
    assert_equal "ai_title", response.parsed_body.dig("meta", "component_id")
    assert_equal true, response.parsed_body.dig("meta", "group")
    assert response.parsed_body.dig("meta", "request_id").present?
    assert_equal "Keep it short.", stored_instruction.instruction
  end

  test "renders component error and does not enqueue job for invalid request" do
    Folio::Ai::Providers::Dummy.stub(:available?, true) do
      assert_no_enqueued_jobs only: Folio::Ai::TextSuggestionsJob do
        post console_api_ai_text_suggestions_path(format: :json),
             params: request_params.except(:message_bus_client_id),
             as: :json
      end
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["data"],
                    I18n.t("folio.ai.console.text_suggestions_component.errors.missing_message_bus_client_id")
  end

  private
    def request_params(**overrides)
      {
        klass: "Folio::Page",
        id: @page.id,
        key: "title",
        group: false,
        message_bus_client_id: "client-1",
        component_id: "ai_title",
        current_form_snapshot_json: {
          "folio_page[title]" => "Draft title",
        }.to_json,
      }.merge(overrides)
    end

    def stored_instruction
      Folio::Ai::UserInstruction.find_by!(user: @superadmin,
                                          site: @site,
                                          integration_key: "folio_pages",
                                          field_key: "title")
    end
end

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
                                { key: :perex, character_limit: 400 },
                              ],
                              groups: [
                                {
                                  key: :meta,
                                  label: "Meta fields",
                                  fields: %i[title perex],
                                },
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
             params: request_params(instructions: "Keep it short."),
             as: :json
      end
    end

    assert_response :ok
    assert_includes response.parsed_body["data"], "f-ai-c-text-suggestions__suggestion--loading"
    assert_equal "ai_title", response.parsed_body.dig("meta", "component_id")
    assert_equal false, response.parsed_body.dig("meta", "grouped")
    assert response.parsed_body.dig("meta", "request_id").present?
    assert_equal "Keep it short.", stored_instruction.instruction
  end

  test "creates grouped loading fragments and enqueues job" do
    Folio::Ai::Providers::Dummy.stub(:available?, true) do
      assert_enqueued_jobs 1, only: Folio::Ai::TextSuggestionsJob do
        post console_api_ai_text_suggestions_path(format: :json),
             params: request_params(grouped: true,
                                    key: "meta",
                                    component_id: "ai_group",
                                    fields: [
                                      { key: "title", component_id: "ai_title" },
                                      { key: "perex", component_id: "ai_perex" },
                                    ]),
             as: :json
      end
    end

    assert_response :ok
    assert_equal true, response.parsed_body.dig("meta", "grouped")
    assert_equal "ai_group", response.parsed_body.dig("meta", "component_id")

    title_fragment = response.parsed_body.dig("meta", "fragments", "ai_title")
    assert_includes title_fragment, "f-ai-c-text-suggestions--grouped"
    assert_equal 1, title_fragment.scan("f-ai-c-text-suggestions__suggestion--loading").size
    assert_not_includes title_fragment, "f-ai-c-text-suggestions__close"
    assert_not_includes title_fragment, "f-ai-c-text-suggestions__instructions"
    assert_includes response.parsed_body.dig("meta", "fragments", "ai_perex"),
                    "f-ai-c-text-suggestions__suggestion--loading"
  end

  test "initial grouped request does not overwrite saved instructions" do
    Folio::Ai::UserInstruction.upsert_instruction!(user: @superadmin,
                                                   site: @site,
                                                   record_key: "folio_pages",
                                                   key: "meta",
                                                   instruction: "Keep variants aligned.")

    Folio::Ai::Providers::Dummy.stub(:available?, true) do
      post console_api_ai_text_suggestions_path(format: :json),
           params: request_params(grouped: true,
                                  key: "meta",
                                  component_id: "ai_group",
                                  fields: [
                                    { key: "title", component_id: "ai_title" },
                                    { key: "perex", component_id: "ai_perex" },
                                  ]),
           as: :json
    end

    assert_response :ok
    assert_equal "Keep variants aligned.",
                 Folio::Ai::UserInstruction.find_by!(user: @superadmin,
                                                     site: @site,
                                                     integration_key: "folio_pages",
                                                     field_key: "meta").instruction
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
        grouped: false,
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

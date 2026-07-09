# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::TextSuggestionRequestTest < ActiveSupport::TestCase
  setup do
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

    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern
    Folio::User.include(Folio::Ai::UserConcern) unless Folio::User < Folio::Ai::UserConcern
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "resolves one registered field request" do
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: { "enabled" => true, "provider" => "dummy" })
    user = create(:folio_user)
    page = create(:folio_page, site:)

    Folio::Ai::UserInstruction.upsert_instruction!(user:,
                                                   site:,
                                                   record_key: "folio_pages",
                                                   key: "title",
                                                   instruction: "Use short words.")

    request = build_request(user:,
                            site:,
                            page:,
                            params: {
                              key: " title ",
                              message_bus_client_id: "client-1",
                              current_form_snapshot_json: { "folio_page[title]" => "Draft title" }.to_json,
                            })

    Folio::Ai::Providers::Dummy.stub(:available?, true) do
      assert_predicate request, :ready?
    end
    assert_not request.grouped?
    assert_equal "title", request.key
    assert_equal "folio_pages", request.record_key
    assert_equal page, request.record
    assert_equal site, request.site
    assert_equal 80, request.field[:character_limit]
    assert_equal({ "folio_page[title]" => "Draft title" }, request.form_snapshot)
    assert_equal "Use short words.", request.instructions
    assert_equal "client-1", request.message_bus_client_id
  end

  test "normalizes grouped fields for child fragments" do
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: { "enabled" => true, "provider" => "dummy" })
    page = create(:folio_page, site:)

    request = build_request(site:,
                            page:,
                            params: {
                              key: "meta",
                              grouped: true,
                              message_bus_client_id: "client-1",
                              fields: [
                                { key: "title", component_id: "ai_title" },
                                { key: "perex", component_id: "ai_perex" },
                                { key: "missing", component_id: "ai_missing" },
                              ],
                            })

    assert_equal [
      { key: "title", label: Folio::Page.human_attribute_name(:title), character_limit: 80, component_id: "ai_title" },
      { key: "perex", label: Folio::Page.human_attribute_name(:perex), character_limit: 400, component_id: "ai_perex" },
    ], request.fields
    assert_equal request.fields, request.job_params[:fields]
    assert_equal true, request.job_params[:grouped]
    assert_equal "meta", request.job_params[:key]
    assert_equal request.fields.first, request.job_params[:field]
  end

  test "uses group site prompt until a user instruction overrides it" do
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: {
                    "enabled" => true,
                    "provider" => "dummy",
                    "integrations" => {
                      "folio_pages" => {
                        "groups" => {
                          "meta" => {
                            "prompt" => "Write title and perex together.",
                          },
                        },
                      },
                    },
                  })
    user = create(:folio_user)
    page = create(:folio_page, site:)

    request = build_request(user:,
                            site:,
                            page:,
                            params: {
                              key: "meta",
                              grouped: true,
                              message_bus_client_id: "client-1",
                            })

    assert_equal "Write title and perex together.", request.instructions

    Folio::Ai::UserInstruction.upsert_instruction!(user:,
                                                   site:,
                                                   record_key: "folio_pages",
                                                   key: "meta",
                                                   instruction: "Use a more direct meta pattern.")

    request = build_request(user:,
                            site:,
                            page:,
                            params: {
                              key: "meta",
                              grouped: true,
                              message_bus_client_id: "client-1",
                            })

    assert_equal "Use a more direct meta pattern.", request.instructions
  end

  test "persists submitted instructions" do
    site = create(Rails.application.config.folio_site_default_test_factory)
    user = create(:folio_user)
    page = create(:folio_page, site:)

    request = build_request(user:,
                            site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                              instructions: "Try a calmer tone.",
                            })

    assert_equal "Try a calmer tone.", request.persist_instructions!
    assert_equal "Try a calmer tone.",
                 Folio::Ai::UserInstruction.find_by!(user:,
                                                     site:,
                                                     integration_key: "folio_pages",
                                                     field_key: "title").instruction
  end

  test "persists submitted group instructions under the group key" do
    site = create(Rails.application.config.folio_site_default_test_factory)
    user = create(:folio_user)
    page = create(:folio_page, site:)

    request = build_request(user:,
                            site:,
                            page:,
                            params: {
                              key: "meta",
                              grouped: true,
                              message_bus_client_id: "client-1",
                              instructions: "Keep the variants aligned.",
                            })

    assert_equal "Keep the variants aligned.", request.persist_instructions!
    assert_equal "Keep the variants aligned.",
                 Folio::Ai::UserInstruction.find_by!(user:,
                                                     site:,
                                                     integration_key: "folio_pages",
                                                     field_key: "meta").instruction
  end

  test "uses site provider and model with dummy fallback model" do
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: { "enabled" => true, "provider" => "dummy" })
    page = create(:folio_page, site:)
    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                            })

    Folio::Ai::Providers::Dummy.stub(:available?, true) do
      provider = request.provider

      assert_instance_of Folio::Ai::Providers::Dummy, provider
      assert_equal Folio::Ai::Providers::Dummy::DEFAULT_MODEL, provider.model
    end
  end

  test "reports request errors" do
    request = build_request(params: { key: "title" })

    assert_equal :missing_message_bus_client_id, request.error_code
  end

  test "reports disabled site" do
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: { "enabled" => false, "provider" => "dummy" })
    page = create(:folio_page, site:)
    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                            })

    assert_equal :site_disabled, request.error_code
  end

  private
    def build_request(site: create(Rails.application.config.folio_site_default_test_factory),
                      user: create(:folio_user),
                      page: create(:folio_page, site:),
                      params: {})
      Folio::Ai::TextSuggestionRequest.new(params: {
                                             klass: "Folio::Page",
                                             id: page.id,
                                           }.merge(params),
                                           current_user: user,
                                           current_site: site,
                                           current_ability: nil)
    end
end

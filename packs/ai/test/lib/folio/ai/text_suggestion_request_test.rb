# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::TextSuggestionRequestTest < ActiveSupport::TestCase
  setup do
    Folio::Ai.reset_registry!
    Folio::Ai.register_record(record_class_name: "Folio::Page",
                              fields: [
                                { key: :title, character_limit: 80 },
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
                                                   field_key: "title",
                                                   instruction: "Use short words.")

    request = build_request(user:,
                            site:,
                            page:,
                            params: {
                              key: " title ",
                              group: "1",
                              message_bus_client_id: "client-1",
                              current_form_snapshot_json: { "folio_page[title]" => "Draft title" }.to_json,
                            })

    Folio::Ai::Providers::Dummy.stub(:available?, true) do
      assert_predicate request, :ready?
    end
    assert_predicate request, :group?
    assert_equal "title", request.key
    assert_equal "folio_pages", request.record_key
    assert_equal page, request.record
    assert_equal site, request.site
    assert_equal 80, request.field[:character_limit]
    assert_equal({ "folio_page[title]" => "Draft title" }, request.form_snapshot)
    assert_equal "Use short words.", request.instructions
    assert_equal "client-1", request.message_bus_client_id
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
      assert_equal Folio::Ai::DEFAULT_DUMMY_MODEL, provider.model
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

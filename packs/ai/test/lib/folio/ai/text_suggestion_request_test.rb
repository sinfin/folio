# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::TextSuggestionRequestTest < ActiveSupport::TestCase
  setup do
    Folio::Ai.reset_registry!
    register_page

    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern
    Folio::User.include(Folio::Ai::UserConcern) unless Folio::User < Folio::Ai::UserConcern
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "resolves one registered field request" do
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings)
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
                              current_form_snapshot_json: {
                                "authenticity_token" => "secret",
                                "folio_page[title]" => "<strong>Draft title</strong>",
                              }.to_json,
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
    assert_equal({ "title" => "Draft title" }, request.form_snapshot)
    assert_equal "Write a short title.", request.site_prompt
    assert_equal "Use short words.", request.instructions
    assert_equal "client-1", request.message_bus_client_id
    assert_equal "Write a short title.", request.job_params[:site_prompt]
    assert_equal "Use short words.", request.job_params[:instructions]
  end

  test "normalizes grouped fields for child fragments" do
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings)
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
    assert_equal "Write title and perex as a set.", request.job_params[:site_prompt]
  end

  test "resolves missing field labels in the current locale" do
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings)
    page = create(:folio_page, site:)

    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                            })

    I18n.with_locale(:cs) do
      assert_equal "Název stránky", request.field[:label]
      assert_equal "Název stránky", request.job_params[:field][:label]
    end
  end

  test "keeps group site prompt separate from user instructions" do
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings(group_prompt: "Write title and perex together."))
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

    assert_equal "Write title and perex together.", request.site_prompt
    assert_equal "", request.instructions

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

    assert_equal "Write title and perex together.", request.site_prompt
    assert_equal "Use a more direct meta pattern.", request.instructions
    assert_equal "Write title and perex together.", request.job_params[:site_prompt]
    assert_equal "Use a more direct meta pattern.", request.job_params[:instructions]
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

  test "reports missing site prompt" do
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings(field_prompt: nil, group_prompt: nil))
    page = create(:folio_page, site:)
    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                            })

    assert_equal :prompt_not_configured, request.error_code
    assert_not_predicate request, :ready?
  end

  test "reports disabled site prompt" do
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings(field_enabled: false))
    page = create(:folio_page, site:)
    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                            })

    assert_equal :prompt_not_configured, request.error_code
    assert_not_predicate request, :ready?
  end

  test "reports missing context when record requires tiptap or atoms content" do
    register_page(content_requirement: :tiptap_or_atoms)
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings)
    page = create(:folio_page, site:, atoms_data_for_search: nil, tiptap_content: nil)

    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                              current_form_snapshot_json: {
                                "folio_page[title]" => "Draft title",
                              }.to_json,
                            })

    assert_equal :missing_context, request.error_code
    assert_not_predicate request, :ready?
  end

  test "accepts current tiptap context when record requires tiptap or atoms content" do
    register_page(content_requirement: :tiptap_or_atoms)
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings)
    page = create(:folio_page, site:, atoms_data_for_search: nil, tiptap_content: nil)

    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                              current_form_snapshot_json: {
                                "folio_page[tiptap_content]" => tiptap_content.to_json,
                              }.to_json,
                            })

    Folio::Ai::Providers::Dummy.stub(:available?, true) do
      assert_predicate request, :ready?
    end
  end

  test "accepts current tiptap embed context without text" do
    register_page(content_requirement: :tiptap_or_atoms)
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings)
    page = create(:folio_page, site:, atoms_data_for_search: nil, tiptap_content: nil)

    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                              current_form_snapshot_json: {
                                "folio_page[tiptap_content]" => tiptap_embed_content.to_json,
                              }.to_json,
                            })

    Folio::Ai::Providers::Dummy.stub(:available?, true) do
      assert_predicate request, :ready?
    end
  end

  test "accepts current atom context when record requires tiptap or atoms content" do
    register_page(content_requirement: :tiptap_or_atoms)
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings)
    page = create(:folio_page, site:, atoms_data_for_search: nil, tiptap_content: nil)

    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                              current_form_snapshot_json: {
                                "folio_page[atoms_attributes][0][data][content]" => "Atom body",
                              }.to_json,
                            })

    Folio::Ai::Providers::Dummy.stub(:available?, true) do
      assert_predicate request, :ready?
    end
  end

  test "ignores persisted body content when record requires current tiptap or atoms content" do
    register_page(content_requirement: :tiptap_or_atoms)
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings)
    page = create(:folio_page, site:)
    page.update_column(:atoms_data_for_search, "Persisted atom text")
    page.update_column(:tiptap_content, tiptap_content.fetch("tiptap_content"))

    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                              current_form_snapshot_json: {
                                "folio_page[title]" => "Draft title",
                              }.to_json,
                            })

    assert_equal :missing_context, request.error_code

    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                              current_form_snapshot_json: {
                                "folio_page[tiptap_content]" => empty_tiptap_content.to_json,
                              }.to_json,
                            })

    assert_equal :missing_context, request.error_code
  end

  test "ignores atoms data cache in submitted form snapshot" do
    register_page(content_requirement: :tiptap_or_atoms)
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings)
    page = create(:folio_page, site:, atoms_data_for_search: nil, tiptap_content: nil)

    request = build_request(site:,
                            page:,
                            params: {
                              key: "title",
                              message_bus_client_id: "client-1",
                              current_form_snapshot_json: {
                                "folio_page[atoms_data_for_search]" => "Cached atom text",
                              }.to_json,
                            })

    assert_equal :missing_context, request.error_code
  end

  test "applies content requirement to grouped requests" do
    register_page(content_requirement: :tiptap_or_atoms)
    site = create(Rails.application.config.folio_site_default_test_factory,
                  ai_settings: ai_settings)
    page = create(:folio_page, site:, atoms_data_for_search: nil, tiptap_content: nil)

    request = build_request(site:,
                            page:,
                            params: {
                              key: "meta",
                              grouped: true,
                              message_bus_client_id: "client-1",
                            })

    assert_equal :missing_context, request.error_code
  end

  private
    def register_page(content_requirement: nil)
      Folio::Ai.reset_registry!
      Folio::Ai.register_record(record_class_name: "Folio::Page",
                                content_requirement:,
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
    end

    def ai_settings(field_prompt: "Write a short title.",
                    group_prompt: "Write title and perex as a set.",
                    field_enabled: nil,
                    group_enabled: nil)
      field = {}
      field["prompt"] = field_prompt if field_prompt
      field["enabled"] = field_enabled unless field_enabled.nil?

      group = {}
      group["prompt"] = group_prompt if group_prompt
      group["enabled"] = group_enabled unless group_enabled.nil?

      {
        "enabled" => true,
        "provider" => "dummy",
        "integrations" => {
          "folio_pages" => {
            "fields" => field.present? ? { "title" => field } : {},
            "groups" => group.present? ? { "meta" => group } : {},
          },
        },
      }
    end

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

    def tiptap_content
      {
        "tiptap_content" => {
          "type" => "doc",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                { "type" => "text", "text" => "Article body" },
              ],
            },
          ],
        },
      }
    end

    def empty_tiptap_content
      {
        "tiptap_content" => {
          "type" => "doc",
          "content" => [],
        },
      }
    end

    def tiptap_embed_content
      {
        "tiptap_content" => {
          "type" => "doc",
          "content" => [
            {
              "type" => "folioTiptapNode",
              "attrs" => {
                "type" => "Dummy::Tiptap::Node::Embed",
                "version" => 1,
                "data" => {
                  "folio_embed_data" => {
                    "active" => true,
                    "type" => "instagram",
                    "url" => "https://www.instagram.com/p/ABC123/",
                  },
                },
              },
            },
          ],
        },
      }
    end
end

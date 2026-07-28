# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::Console::TextSuggestionsGroupComponentTest < Folio::Console::ComponentTest
  setup do
    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern
    Folio::User.include(Folio::Ai::UserConcern) unless Folio::User < Folio::Ai::UserConcern

    Folio::Ai.reset_registry!
    Folio::Ai.register_record(record_class_name: "Folio::Page",
                              fields: %i[title perex],
                              groups: [
                                {
                                  key: :meta,
                                  label: "Meta fields",
                                  fields: %i[title perex],
                                },
                              ])

    @site = create(Rails.application.config.folio_site_default_test_factory,
                   ai_settings: ai_settings)
    @page = create(:folio_page, site: @site)
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "renders group controls around child content" do
    render_component do |form|
      render_inline(Folio::Ai::Console::TextSuggestionsGroupComponent.new(form:,
                                                                         key: :meta)) do
        "Child inputs"
      end
    end

    assert_selector(".f-ai-c-text-suggestions-group", text: "Child inputs")
    assert_selector(".f-ai-c-text-suggestions-group__button", text: "AI suggestions for all variants")
    assert_selector(".f-ai-c-text-suggestions-group__button-loader.folio-loader", visible: :all)
    assert_selector(".f-ai-c-text-suggestions-group__close[aria-label='Close'][hidden]", visible: :all)
    assert_selector(".f-ai-c-text-suggestions-group__panel[hidden]", visible: :all)
    assert_selector("textarea[placeholder='Custom AI instructions (optional) ...']", visible: :all)

    fields = JSON.parse(page.find(".f-ai-c-text-suggestions-group")["data-f-ai-c-text-suggestions-group-fields-value"])
    assert_equal [
      { "key" => "title", "component_id" => "folio_ai_text_suggestions_page_title" },
      { "key" => "perex", "component_id" => "folio_ai_text_suggestions_page_perex" },
    ], fields
  end

  test "uses configured input ids for grouped child component ids" do
    render_component do |form|
      render_inline(Folio::Ai::Console::TextSuggestionsGroupComponent.new(form:,
                                                                         key: :meta,
                                                                         fields: [
                                                                           { key: :title, input_id: "custom_title_input" },
                                                                         ])) do
        vc_test_controller.view_context.safe_join([
          form.input(:title,
                     ai: true,
                     input_html: { id: "custom_title_input" }),
          form.input(:perex, ai: true),
        ])
      end
    end

    group = page.find(".f-ai-c-text-suggestions-group")
    fields = JSON.parse(group["data-f-ai-c-text-suggestions-group-fields-value"])

    assert_equal [
      { "key" => "title", "component_id" => "folio_ai_text_suggestions_custom_title_input" },
      { "key" => "perex", "component_id" => "folio_ai_text_suggestions_page_perex" },
    ], fields
    assert_selector(".f-ai-input[data-f-ai-input-component-id-value='folio_ai_text_suggestions_custom_title_input']")
  end

  test "does not render without registered fields" do
    render_component do |form|
      render_inline(Folio::Ai::Console::TextSuggestionsGroupComponent.new(form:,
                                                                         key: :missing)) do
        "Child inputs"
      end
    end

    assert_text("Child inputs")
    assert_no_selector(".f-ai-c-text-suggestions-group")
  end

  test "does not render without group prompt" do
    @site.update!(ai_settings: ai_settings(group_prompt: nil))

    render_component do |form|
      render_inline(Folio::Ai::Console::TextSuggestionsGroupComponent.new(form:,
                                                                         key: :meta)) do
        "Child inputs"
      end
    end

    assert_text("Child inputs")
    assert_no_selector(".f-ai-c-text-suggestions-group")
  end

  test "does not render when group is disabled" do
    @site.update!(ai_settings: ai_settings(group_enabled: false))

    render_component do |form|
      render_inline(Folio::Ai::Console::TextSuggestionsGroupComponent.new(form:,
                                                                         key: :meta)) do
        "Child inputs"
      end
    end

    assert_text("Child inputs")
    assert_no_selector(".f-ai-c-text-suggestions-group")
  end

  test "does not prefill instructions with group prompt" do
    render_component do |form|
      render_inline(Folio::Ai::Console::TextSuggestionsGroupComponent.new(form:,
                                                                         key: :meta))
    end

    assert_no_selector(".f-ai-c-text-suggestions-group__instructions",
                       text: "Write title and perex as a set.",
                       visible: :all)
  end

  test "prefills saved group instructions" do
    user = create(:folio_user)
    Folio::Ai::UserInstruction.upsert_instruction!(user:,
                                                   site: @site,
                                                   record_key: "folio_pages",
                                                   key: "meta",
                                                   instruction: "Keep title and perex aligned.")

    render_component(user:) do |form|
      render_inline(Folio::Ai::Console::TextSuggestionsGroupComponent.new(form:,
                                                                         key: :meta))
    end

    assert_selector(".f-ai-c-text-suggestions-group__instructions",
                    text: "Keep title and perex aligned.",
                    visible: :all)
    assert_selector(".f-ai-c-text-suggestions-group__instructions[data-f-c-form-footer-autosave-disabled='true']",
                    visible: :all)
  end

  private
    def ai_settings(group_prompt: "Write title and perex as a set.",
                    group_enabled: nil)
      group = {}
      group["prompt"] = group_prompt if group_prompt
      group["enabled"] = group_enabled unless group_enabled.nil?

      groups = group.present? ? { "meta" => group } : {}

      {
        "enabled" => true,
        "provider" => "dummy",
        "integrations" => {
          "folio_pages" => {
            "groups" => groups,
          },
        },
      }
    end

    def render_component(user: nil, &block)
      I18n.with_locale(:en) do
        Folio::Current.stub(:user, user) do
          Folio::Ai::Providers::Dummy.stub(:available?, true) do
            vc_test_controller.view_context.simple_form_for(@page, url: "/", &block)
          end
        end
      end
    end
end

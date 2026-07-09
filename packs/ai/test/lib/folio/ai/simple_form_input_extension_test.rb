# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")

class Folio::Ai::SimpleFormInputExtensionTest < ActionView::TestCase
  include SimpleForm::ActionViewExtensions::FormHelper

  setup do
    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern

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

    @site = create(Rails.application.config.folio_site_default_test_factory,
                   ai_settings: ai_settings)
    @page = create(:folio_page, site: @site)
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "renders ai controls for registered persisted string inputs" do
    html = with_dummy_provider do
      simple_form_for @page, url: "/" do |f|
        concat(f.input :title, ai: true)
      end
    end

    page = Capybara.string(html)
    wrapper = page.find(".form-group.f-ai-input")

    assert_includes wrapper["class"].split, "f-ai-input"
    assert_includes wrapper["class"].split, "form-group--with-ai-text-suggestions"

    assert_ai_values(wrapper)
    assert page.has_css?(".f-ai-input__button svg", count: 1)
    assert page.has_css?(".f-ai-input__undo[hidden]", count: 1, visible: :all)
    assert page.has_css?(".f-ai-c-input-controls", count: 1)
    assert page.has_css?(".f-ai-input__custom-html", count: 1)
  end

  test "renders localized ai control label" do
    html = I18n.with_locale(:cs) do
      with_dummy_provider do
        simple_form_for @page, url: "/" do |f|
          concat(f.input :title, ai: true)
        end
      end
    end

    assert Capybara.string(html).has_css?(".f-ai-input__button", text: "AI návrhy")
  end

  test "uses custom input id for the ai component id" do
    html = with_dummy_provider do
      simple_form_for @page, url: "/" do |f|
        concat(f.input :title,
                       ai: true,
                       input_html: { id: "custom_title_input" })
      end
    end

    wrapper = Capybara.string(html).find(".form-group.f-ai-input")

    assert_equal "folio_ai_text_suggestions_custom_title_input",
                 wrapper["data-f-ai-input-component-id-value"]
  end

  test "does not render controls for unregistered fields" do
    html = with_dummy_provider do
      simple_form_for @page, url: "/" do |f|
        concat(f.input :slug, ai: true)
      end
    end

    page = Capybara.string(html)

    assert page.has_no_css?(".f-ai-input__controls")
    assert page.has_no_css?(".f-ai-input__custom-html")
  end

  test "does not render controls when field prompt is blank" do
    @site.update!(ai_settings: ai_settings(field_prompt: nil))

    html = with_dummy_provider do
      simple_form_for @page, url: "/" do |f|
        concat(f.input :title, ai: true)
      end
    end

    page = Capybara.string(html)

    assert page.has_no_css?(".f-ai-input")
    assert page.has_no_css?(".f-ai-input__button")
  end

  test "does not render individual button when field is disabled" do
    @site.update!(ai_settings: ai_settings(field_enabled: false))

    html = with_dummy_provider do
      simple_form_for @page, url: "/" do |f|
        concat(f.input :title, ai: true)
      end
    end

    page = Capybara.string(html)

    assert page.has_no_css?(".f-ai-input")
    assert page.has_no_css?(".f-ai-input__button")
  end

  test "keeps grouped child wrapper without individual button" do
    @site.update!(ai_settings: ai_settings(field_prompt: nil,
                                           field_enabled: false,
                                           group_prompt: "Write meta fields together."))

    html = with_dummy_provider do
      simple_form_for @page, url: "/" do |f|
        concat(f.input :title, ai: true)
      end
    end

    page = Capybara.string(html)

    assert page.has_css?(".form-group.f-ai-input")
    assert page.has_no_css?(".f-ai-input__button")
    assert page.has_css?(".f-ai-input__undo[hidden]", visible: :all)
    assert page.has_css?(".f-ai-input__custom-html", count: 1)
  end

  test "does not render controls when no provider is available" do
    html = Folio::Ai.stub(:provider_for, ->(**) { raise Folio::Ai::ProviderError }) do
      simple_form_for @page, url: "/" do |f|
        concat(f.input :title, ai: true)
      end
    end

    page = Capybara.string(html)

    assert page.has_no_css?(".f-ai-input__controls")
  end

  test "does not render controls when site AI is disabled" do
    @site.update!(ai_settings: { "enabled" => false, "provider" => "dummy" })

    html = with_dummy_provider do
      simple_form_for @page, url: "/" do |f|
        concat(f.input :title, ai: true)
      end
    end

    page = Capybara.string(html)

    assert page.has_no_css?(".f-ai-input__controls")
  end

  private
    def ai_settings(field_prompt: "Write a short title.",
                    group_prompt: nil,
                    field_enabled: nil,
                    group_enabled: nil)
      field = {}
      field["prompt"] = field_prompt if field_prompt
      field["enabled"] = field_enabled unless field_enabled.nil?

      fields = field.present? ? { "title" => field } : {}

      group = {}
      group["prompt"] = group_prompt if group_prompt
      group["enabled"] = group_enabled unless group_enabled.nil?

      groups = group.present? ? { "meta" => group } : {}

      {
        "enabled" => true,
        "provider" => "dummy",
        "integrations" => {
          "folio_pages" => {
            "fields" => fields,
            "groups" => groups,
          },
        },
      }
    end

    def with_dummy_provider(&block)
      Folio::Ai.config.stub(:enabled?, true) do
        Folio::Ai::Providers::Dummy.stub(:available?, true, &block)
      end
    end

    def assert_ai_values(wrapper)
      assert_equal "/console/api/ai/text_suggestions", wrapper["data-f-ai-input-url-value"]
      assert_equal "Folio::Page", wrapper["data-f-ai-input-klass-value"]
      assert_equal @page.id.to_s, wrapper["data-f-ai-input-record-id-value"]
      assert_equal "title", wrapper["data-f-ai-input-key-value"]
      assert_equal "false", wrapper["data-f-ai-input-grouped-value"]
      assert_equal "3", wrapper["data-f-ai-input-suggestion-count-value"]
      assert_equal "folio_ai_text_suggestions_page_title", wrapper["data-f-ai-input-component-id-value"]
    end
end

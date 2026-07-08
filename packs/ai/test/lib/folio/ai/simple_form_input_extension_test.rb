# frozen_string_literal: true

require "test_helper"
require Folio::Engine.root.join("packs/ai/lib/folio/ai")
load Folio::Engine.root.join("packs/ai/app/overrides/lib/simple_form/inputs/base_ai_override.rb")

class Folio::Ai::SimpleFormInputExtensionTest < ActionView::TestCase
  include SimpleForm::ActionViewExtensions::FormHelper

  setup do
    Folio::Site.include(Folio::Ai::SiteConcern) unless Folio::Site < Folio::Ai::SiteConcern

    Folio::Ai.reset_registry!
    Folio::Ai.register_record(record_class_name: "Folio::Page",
                              fields: [
                                { key: :title, character_limit: 80 },
                              ])

    @site = create(Rails.application.config.folio_site_default_test_factory,
                   ai_settings: { "provider" => "dummy" })
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
    input = wrapper.find("[data-f-ai-input-target='input']")

    assert_includes wrapper["class"].split, "f-ai-input"
    assert_includes wrapper["class"].split, "form-group--with-ai-text-suggestions"
    assert_includes wrapper["data-action"].split, "f-ai-c-input-controls:toggle->f-ai-input#toggle"
    assert_includes wrapper["data-action"].split, "f-ai-c-input-controls:undo->f-ai-input#undoSuggestion"
    assert_includes wrapper["data-action"].split, "f-ai-input/message->f-ai-input#onMessage"
    assert_not_includes wrapper["data-action"].split, "click@window->f-ai-input#onWindowClick"
    assert_not_includes wrapper["data-action"].split, "keydown@window->f-ai-input#onWindowKeydown"
    assert_equal "input", input["data-f-ai-input-target"]
    assert_includes input["data-action"].split, "input->f-ai-input#onInput"

    assert_ai_values(wrapper)
    assert page.has_css?(".f-ai-input__button svg", count: 1)
    assert page.has_css?(".f-ai-input__undo[hidden]", count: 1, visible: :all)
    assert page.has_css?(".f-ai-c-input-controls[data-controller='f-ai-c-input-controls']", count: 1)
    assert page.has_css?(".f-ai-input__custom-html[data-f-ai-c-input-controls-target='customHtml']", count: 1)
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

  test "does not render controls when no provider is available" do
    html = Folio::Ai.stub(:provider_for, ->(**) { raise Folio::Ai::ProviderError }) do
      simple_form_for @page, url: "/" do |f|
        concat(f.input :title, ai: true)
      end
    end

    page = Capybara.string(html)

    assert page.has_no_css?(".f-ai-input__controls")
  end

  private
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
      assert_equal "false", wrapper["data-f-ai-input-group-value"]
      assert_equal "3", wrapper["data-f-ai-input-suggestion-count-value"]
      assert_equal "folio_ai_text_suggestions_page_title", wrapper["data-f-ai-input-component-id-value"]
      assert_equal "45000", wrapper["data-f-ai-input-request-timeout-ms-value"]
    end
end

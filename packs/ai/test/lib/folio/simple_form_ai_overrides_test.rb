# frozen_string_literal: true

require "test_helper"

class Folio::Ai::SimpleFormOverridesTest < ActionView::TestCase
  include SimpleForm::ActionViewExtensions::FormHelper
  include Folio::Console::FormsHelper
  include Folio::IconHelper

  setup do
    @original_openai_api_key = ENV["FOLIO_AI_OPENAI_API_KEY"]
    ENV["FOLIO_AI_OPENAI_API_KEY"] = "secret"
  end

  teardown do
    if @original_openai_api_key
      ENV["FOLIO_AI_OPENAI_API_KEY"] = @original_openai_api_key
    else
      ENV.delete("FOLIO_AI_OPENAI_API_KEY")
    end
    Folio::Ai.reset_registry!
  end

  test "attaches AI suggestions to eligible string input with explicit integration key" do
    site = create_site(force: true)
    user = create(:folio_user, auth_site: site)
    record = create(:folio_page, site:)
    register_ai_field(auto_attach: false)
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site
    Folio::Current.user = user

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title,
                       ai: {
                         integration_key: :articles,
                       })
      end
    end

    page = Capybara.string(html)

    assert page.has_css?(".form-group--with-ai-text-suggestions")
    assert page.has_css?("[data-controller='f-ai-input']")
    assert page.has_css?("[data-f-ai-input-target='input'][data-action*='onInputSyncAiSuggestion']")
    assert page.has_css?("[data-f-ai-input-target='undo']", visible: :hidden)
    assert page.has_css?("[data-action*='f-ai-c-text-suggestions:accept']")
    assert page.has_css?("[data-f-ai-input-url-value='/console/api/ai_text_suggestions/text_suggestions']")
    assert page.has_css?("[data-f-ai-input-instructions-url-value='/console/api/ai_text_suggestions/instructions']")
    assert page.has_css?("[data-f-ai-input-klass-value='Folio::Page']")
    assert page.has_css?("[data-f-ai-input-record-id-value='#{record.id}']")
    assert page.has_css?("[data-f-ai-input-integration-key-value='articles']")
    assert page.has_css?("[data-f-ai-input-field-key-value='title']")
    assert page.has_css?("[data-f-ai-input-current-state-policy-value='current_form_snapshot']")
    assert page.has_css?(".form-group__custom-html .f-ai-input__button")
    assert page.has_css?(".form-group__custom-html .f-ai-input__undo", visible: :hidden)
    assert page.has_css?(".form-group__custom-html [data-f-ai-input-target='customHtml']")
    assert page.has_no_css?(".form-group__custom-html .f-ai-c-text-suggestions")
    assert page.has_no_css?(".f-ai-c-text-suggestions")
    assert page.has_no_css?("[data-controller='f-ai-c-text-suggestions-actions']")
    assert page.has_no_css?("[data-f-ai-c-text-suggestions-target-selector-value]")
  end

  test "infers integration key from the form object table name" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field(integration_key: :folio_pages)
    site.update!(ai_settings: enabled_ai_settings(integration_key: :folio_pages))
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title, ai: true)
      end
    end

    page = Capybara.string(html)

    assert page.has_css?("[data-f-ai-input-integration-key-value='folio_pages']")
    assert page.has_css?("[data-f-ai-input-field-key-value='title']")
  end

  test "supports explicit persisted record policy" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title,
                       ai: {
                         integration_key: :articles,
                         current_state_policy: :persisted_record,
                       })
      end
    end

    page = Capybara.string(html)

    assert page.has_css?("[data-f-ai-input-current-state-policy-value='persisted_record']")
  end

  test "attaches AI suggestions to eligible text input" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field(key: :perex, character_limit: 400)
    site.update!(ai_settings: enabled_ai_settings(field_key: :perex))
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:perex,
                       as: :text,
                       ai: {
                         integration_key: :articles,
                       })
      end
    end

    page = Capybara.string(html)

    assert page.has_css?("[data-controller='f-ai-input']")
    assert page.has_css?("textarea[data-f-ai-input-target='input']")
    assert page.has_css?("[data-f-ai-input-field-key-value='perex']")
  end

  test "does not attach AI suggestions without prompt" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings(prompt: ""))
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title,
                       ai: {
                         integration_key: :articles,
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-ai-input']")
  end

  test "does not attach AI suggestions for unregistered field" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    Folio::Ai.reset_registry!
    Folio::Ai.register_integration(key: :articles,
                                   record_class_name: "Folio::Page",
                                   fields: [])
    site.update!(ai_settings: {
                   enabled: true,
                   integrations: {
                     articles: {
                       fields: {},
                     },
                   },
                 })
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title,
                       ai: {
                         integration_key: :articles,
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-ai-input']")
  end

  test "does not attach AI suggestions when provider is unavailable" do
    ENV.delete("FOLIO_AI_OPENAI_API_KEY")
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title,
                       ai: {
                         integration_key: :articles,
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-ai-input']")
  end

  test "does not attach AI suggestions to a new record" do
    site = create_site(force: true)
    record = build(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title,
                       ai: {
                         integration_key: :articles,
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-ai-input']")
  end

  test "does not attach AI suggestions to a new record with current form snapshot policy" do
    site = create_site(force: true)
    record = build(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title,
                       ai: {
                         integration_key: :articles,
                         current_state_policy: :current_form_snapshot,
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-ai-input']")
  end

  test "does not attach AI suggestions to disabled or readonly inputs" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title,
                       disabled: true,
                       ai: {
                         integration_key: :articles,
                       })
        concat f.input(:title,
                       readonly: true,
                       ai: {
                         integration_key: :articles,
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-ai-input']")
  end

  test "does not attach AI suggestions when rendered input type does not match string column" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title,
                       as: :text,
                       ai: {
                         integration_key: :articles,
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-ai-input']")
  end

  test "does not attach AI suggestions when rendered input type does not match text column" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field(key: :perex)
    site.update!(ai_settings: enabled_ai_settings(field_key: :perex))
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:perex,
                       as: :string,
                       ai: {
                         integration_key: :articles,
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-ai-input']")
  end

  test "does not attach AI suggestions for unsupported column type" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field(key: :published)
    site.update!(ai_settings: enabled_ai_settings(field_key: :published))
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:published,
                       as: :string,
                       ai: {
                         integration_key: :articles,
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-ai-input']")
  end

  test "does not attach AI suggestions when ai option is false" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title, ai: false)
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-ai-input']")
  end

  private
    def cell(name, model = nil, options = {}, &block)
      options[:context] ||= {}
      options[:context][:view] = self
      @controller.cell(name, model, options, &block)
    end

    def register_ai_field(integration_key: :articles, key: :title, auto_attach: true, character_limit: 120)
      Folio::Ai.reset_registry!
      Folio::Ai.register_integration(key: integration_key,
                                     record_class_name: "Folio::Page",
                                     fields: [
                                       Folio::Ai::Field.new(key:,
                                                            auto_attach:,
                                                            character_limit:),
                                     ])
    end

    def enabled_ai_settings(integration_key: :articles, field_key: :title, prompt: "Write a title.")
      {
        enabled: true,
        integrations: {
          integration_key => {
            fields: {
              field_key => {
                enabled: true,
                prompt:,
              },
            },
          },
        },
      }
    end
end

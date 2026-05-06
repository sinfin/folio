# frozen_string_literal: true

require "test_helper"

class Folio::Ai::SimpleFormOverridesTest < ActionView::TestCase
  include SimpleForm::ActionViewExtensions::FormHelper
  include Folio::Console::FormsHelper

  teardown do
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
                         endpoint: "/ai",
                       })
      end
    end

    page = Capybara.string(html)

    assert page.has_css?(".form-group--with-ai-text-suggestions")
    assert page.has_css?("[data-controller='f-input-ai-text-suggestions']")
    assert page.has_css?("[data-f-input-ai-text-suggestions-target='input']")
    assert page.has_css?("[data-f-input-ai-text-suggestions-endpoint-value='/ai']")
    assert page.has_css?("[data-f-input-ai-text-suggestions-integration-key-value='articles']")
    assert page.has_css?("[data-f-input-ai-text-suggestions-field-key-value='title']")
    assert page.has_css?("[data-f-input-ai-text-suggestions-current-state-policy-value='persisted_record']")
    assert page.has_css?("[data-f-input-ai-text-suggestions-character-limit-value='120']")
    assert page.has_css?("[data-f-input-ai-text-suggestions-initial-instructions-value='']")
    assert page.has_no_css?(".form-group__input-controls .f-ai-c-text-suggestions")
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
        concat f.input(:title, ai: { endpoint: "/ai" })
      end
    end

    page = Capybara.string(html)

    assert page.has_css?("[data-f-input-ai-text-suggestions-integration-key-value='folio_pages']")
    assert page.has_css?("[data-f-input-ai-text-suggestions-field-key-value='title']")
  end

  test "attaches AI suggestions to eligible text input" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field(key: :perex, input_types: %i[text], character_limit: 400)
    site.update!(ai_settings: enabled_ai_settings(field_key: :perex))
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:perex,
                       as: :text,
                       ai: {
                         integration_key: :articles,
                         endpoint: "/ai",
                       })
      end
    end

    page = Capybara.string(html)

    assert page.has_css?("[data-controller='f-input-ai-text-suggestions']")
    assert page.has_css?("textarea[data-f-input-ai-text-suggestions-target='input']")
    assert page.has_css?("[data-f-input-ai-text-suggestions-field-key-value='perex']")
    assert page.has_css?("[data-f-input-ai-text-suggestions-character-limit-value='400']")
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
                         endpoint: "/ai",
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-input-ai-text-suggestions']")
  end

  test "does not attach AI suggestions for unregistered field" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    Folio::Ai.reset_registry!
    Folio::Ai.register_integration(:articles, fields: [])
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title,
                       ai: {
                         integration_key: :articles,
                         endpoint: "/ai",
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-input-ai-text-suggestions']")
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
                         endpoint: "/ai",
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-input-ai-text-suggestions']")
  end

  test "attaches AI suggestions to a new record with current form snapshot policy" do
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
                         endpoint: "/ai",
                         current_state_policy: :current_form_snapshot,
                       })
      end
    end

    page = Capybara.string(html)

    assert page.has_css?("[data-controller='f-input-ai-text-suggestions']")
    assert page.has_css?("[data-f-input-ai-text-suggestions-current-state-policy-value='current_form_snapshot']")
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
                         endpoint: "/ai",
                       })
        concat f.input(:title,
                       readonly: true,
                       ai: {
                         integration_key: :articles,
                         endpoint: "/ai",
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-input-ai-text-suggestions']")
  end

  test "does not attach AI suggestions when input type is not registered for the field" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field(input_types: %i[text])
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site

    html = with_ai_config(enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat f.input(:title,
                       ai: {
                         integration_key: :articles,
                         endpoint: "/ai",
                       })
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?("[data-controller='f-input-ai-text-suggestions']")
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

    assert_not page.has_css?("[data-controller='f-input-ai-text-suggestions']")
  end

  test "raises developer-facing error when endpoint is missing" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site

    error = assert_raises(ArgumentError) do
      with_ai_config(enabled: true) do
        simple_form_for(record, url: "/") do |f|
          concat f.input(:title, ai: { integration_key: :articles })
        end
      end
    end

    assert_includes error.message, "ai: requires endpoint"
  end

  private
    def register_ai_field(integration_key: :articles, key: :title, auto_attach: true, input_types: %i[string], character_limit: 120)
      Folio::Ai.reset_registry!
      Folio::Ai.register_integration(integration_key,
                                     fields: [
                                       Folio::Ai::Field.new(key:,
                                                            auto_attach:,
                                                            input_types:,
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

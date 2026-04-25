# frozen_string_literal: true

require "test_helper"

class Folio::Ai::SimpleFormOverridesTest < ActionView::TestCase
  include SimpleForm::ActionViewExtensions::FormHelper
  include Folio::Console::FormsHelper

  teardown do
    Folio::Ai.reset_registry!
  end

  test "auto-attaches AI suggestions to eligible string input" do
    site = create_site(force: true)
    user = create(:folio_user, auth_site: site)
    record = create(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site
    Folio::Current.user = user

    html = with_config(folio_ai_enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat(folio_ai_form_context(integration_key: :articles,
                                     endpoint: "/ai",
                                     record:) do
          f.input(:title)
        end)
      end
    end

    page = Capybara.string(html)

    assert page.has_css?(".form-group__input-controls .f-c-ai-text-suggestions")
    assert page.has_css?("[data-f-c-ai-text-suggestions-target-selector-value='#page_title']")
  end

  test "does not auto-attach AI suggestions without prompt" do
    site = create_site(force: true)
    record = create(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings(prompt: ""))
    Folio::Current.site = site

    html = with_config(folio_ai_enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat(folio_ai_form_context(integration_key: :articles,
                                     endpoint: "/ai",
                                     record:) do
          f.input(:title)
        end)
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?(".f-c-ai-text-suggestions")
  end

  test "does not auto-attach AI suggestions to a new record" do
    site = create_site(force: true)
    record = build(:folio_page, site:)
    register_ai_field
    site.update!(ai_settings: enabled_ai_settings)
    Folio::Current.site = site

    html = with_config(folio_ai_enabled: true) do
      simple_form_for(record, url: "/") do |f|
        concat(folio_ai_form_context(integration_key: :articles,
                                     endpoint: "/ai",
                                     record:) do
          f.input(:title)
        end)
      end
    end

    page = Capybara.string(html)

    assert_not page.has_css?(".f-c-ai-text-suggestions")
  end

  private
    def register_ai_field
      Folio::Ai.reset_registry!
      Folio::Ai.register_integration(:articles,
                                     fields: [
                                       Folio::Ai::Field.new(key: :title,
                                                            auto_attach: true,
                                                            input_types: %i[string],
                                                            character_limit: 120),
                                     ])
    end

    def enabled_ai_settings(prompt: "Write a title.")
      {
        enabled: true,
        integrations: {
          articles: {
            fields: {
              title: {
                enabled: true,
                prompt:,
              },
            },
          },
        },
      }
    end
end

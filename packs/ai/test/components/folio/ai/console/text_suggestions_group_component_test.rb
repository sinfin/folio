# frozen_string_literal: true

require "test_helper"

class Folio::Ai::Console::TextSuggestionsGroupComponentTest < Folio::Console::ComponentTest
  setup do
    Folio::Ai.reset_registry!
    Folio::Ai.register_integration(key: :articles,
                                   record_class_name: "Folio::Page",
                                     fields: [
                                       Folio::Ai::Field.new(key: :title),
                                     Folio::Ai::Field.new(key: :all_ai_inputs,
                                                          label: "All AI inputs"),
                                   ])

    @site = create_site(force: true)
    @site.update!(ai_settings: enabled_ai_settings)
    @user = create(:folio_user, auth_site: @site)
    Folio::Current.site = @site
    Folio::Current.user = @user
  end

  teardown do
    Folio::Ai.reset_registry!
  end

  test "renders global controls without a title" do
    with_ai_config(enabled: true) do
      Folio::Ai.config.stub(:provider_api_key_env_values, { openai: "secret" }) do
        render_inline(component) do
          <<~HTML.html_safe
            <div class="f-ai-input"
                 data-f-ai-input-integration-key-value="articles"
                 data-f-ai-input-field-key-value="title">
              Title field
            </div>
          HTML
        end
      end
    end

    assert_selector(".f-ai-c-text-suggestions-group")
    assert_no_selector(".f-ai-c-text-suggestions-group__title")
    assert_selector("[data-controller='f-ai-c-text-suggestions-group']")
    assert_selector("[data-f-ai-c-text-suggestions-group-url-value='/console/api/ai_text_suggestions/batch_text_suggestions']")
    assert_selector("[data-f-ai-c-text-suggestions-group-instructions-url-value='/console/api/ai_text_suggestions/batch_instructions']")
    assert_selector("[data-f-ai-c-text-suggestions-group-state-value='idle']")
    assert_selector("[data-action*='f-ai-c-text-suggestions-group-controls:generate->f-ai-c-text-suggestions-group#generate']")
    assert_selector("[data-action*='f-ai-c-text-suggestions-group-controls:close->f-ai-c-text-suggestions-group#close']")
    assert_selector("[data-action*='f-ai-c-text-suggestions-group-instructions:regenerate->f-ai-c-text-suggestions-group#regenerate']")
    assert_selector(".f-ai-c-text-suggestions-group-controls")
    assert_selector(".f-ai-c-text-suggestions-group-instructions")
    assert_text "Title field"
  end

  private
    def component
      Folio::Ai::Console::TextSuggestionsGroupComponent.new(integration_key: :articles,
                                                            field_key: :all_ai_inputs)
    end

    def enabled_ai_settings
      {
        enabled: true,
        integrations: {
          articles: {
            fields: {
              title: {
                prompt: "Write a title.",
              },
              all_ai_inputs: {
                prompt: "Write all AI-enabled inputs.",
              },
            },
          },
        },
      }
    end
end

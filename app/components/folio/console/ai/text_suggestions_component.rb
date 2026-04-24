# frozen_string_literal: true

class Folio::Console::Ai::TextSuggestionsComponent < Folio::Console::ApplicationComponent
  def initialize(integration_key:,
                 field_key:,
                 endpoint:,
                 target_selector:,
                 user_instructions: nil,
                 character_limit: nil,
                 suggestion_count: Folio::Ai::ResponseNormalizer::DEFAULT_SUGGESTION_COUNT,
                 field_label: nil,
                 button_label: nil,
                 class_name: nil,
                 available: true)
    @integration_key = integration_key.to_s
    @field_key = field_key.to_s
    @endpoint = endpoint
    @target_selector = target_selector
    @user_instructions = user_instructions.to_s
    @character_limit = character_limit
    @suggestion_count = suggestion_count
    @field_label = field_label
    @button_label = button_label
    @class_name = class_name
    @available = available
  end

  def render?
    @available && @endpoint.present? && @target_selector.present?
  end

  private
    def data
      stimulus_controller("f-c-ai-text-suggestions",
                          values: stimulus_values,
                          action: stimulus_actions,
                          classes: %w[open loading])
    end

    def stimulus_values
      {
        endpoint: @endpoint,
        integration_key: @integration_key,
        field_key: @field_key,
        target_selector: @target_selector,
        suggestion_count: @suggestion_count,
        character_limit: @character_limit,
        initial_instructions: @user_instructions,
        loading_text: t(".loading_text"),
        generic_error_text: t(".generic_error_text"),
        missing_context_text: t(".missing_context_text"),
        copy_label: t(".copy_label"),
        accept_label: t(".accept_label"),
        chars_label: t(".chars_label"),
      }.compact
    end

    def stimulus_actions
      {
        "click@window": "onWindowClick",
        "keydown@window": "onWindowKeydown",
        "folio:ai-text-suggestions:open@document": "onOtherPanelOpen",
      }
    end

    def panel_title
      if @field_label.present?
        t(".panel_title_with_field", field: @field_label)
      else
        t(".panel_title")
      end
    end

    def button_label
      @button_label.presence || t(".button_label")
    end
end

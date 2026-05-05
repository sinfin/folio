# frozen_string_literal: true

class Folio::Ai::Console::TextSuggestionsComponent < Folio::Console::ApplicationComponent
  BEM_CLASS_NAME = "f-ai-c-text-suggestions"

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
                 available: true,
                 id: nil,
                 external_controls: false,
                 external_button_selector: nil,
                 external_undo_selector: nil,
                 show_meta: false,
                 current_state_policy: :persisted_record,
                 request_timeout_ms: Folio::Ai.client_request_timeout_ms)
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
    @id = id
    @external_controls = external_controls
    @external_button_selector = external_button_selector
    @external_undo_selector = external_undo_selector
    @show_meta = show_meta
    @current_state_policy = current_state_policy.to_s
    @request_timeout_ms = request_timeout_ms
  end

  def render?
    @available && @endpoint.present? && @target_selector.present?
  end

  private
    def original_bem_class_name
      BEM_CLASS_NAME
    end

    def data
      stimulus_controller("f-ai-c-text-suggestions",
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
        request_timeout_text: t(".request_timeout_text"),
        missing_context_text: t(".missing_context_text"),
        copy_label: t(".copy_label"),
        copy_button_label: t(".copy_button_label"),
        accept_label: t(".accept_label"),
        accept_button_label: t(".accept_button_label"),
        chars_label: t(".chars_label"),
        external_button_selector: @external_button_selector,
        external_undo_selector: @external_undo_selector,
        show_meta: @show_meta,
        current_state_policy: @current_state_policy,
        request_timeout_ms: @request_timeout_ms,
      }.compact
    end

    def html_id
      @id
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

    def sparkles_icon
      Folio::Ai::Icons.sparkles(self)
    end

    def undo_icon
      Folio::Ai::Icons.undo(self)
    end

    def external_controls?
      @external_controls
    end
end

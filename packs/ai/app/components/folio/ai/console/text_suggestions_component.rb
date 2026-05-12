# frozen_string_literal: true

class Folio::Ai::Console::TextSuggestionsComponent < Folio::Console::ApplicationComponent
  CONTROLLER_NAME = "f-ai-c-text-suggestions"

  def initialize(result:,
                 component_id:,
                 field_label:,
                 show_meta: false,
                 integration_key: nil,
                 field_key: nil,
                 loading: false)
    @result = result
    @component_id = component_id
    @field_label = field_label
    @show_meta = show_meta
    @integration_key = integration_key
    @field_key = field_key
    @loading = loading
  end

  private
    def component_data
      stimulus_controller(CONTROLLER_NAME,
                          values: {
                            integration_key: @integration_key,
                            field_key: @field_key,
                          }.compact,
                          action: { "f-ai-input:suggestionStale" => "clearSuggestionSelection" })
    end

    def component_class
      "f-ai-c-text-suggestions--loading" if loading?
    end

    def panel_data
      stimulus_action(click: "stopPropagation")
    end

    def close_data
      stimulus_action(click: "close")
    end

    def suggestion_data(suggestion)
      stimulus_data(action: { click: "accept" },
                    params: suggestion_params(suggestion),
                    target: "suggestion")
    end

    def accept_suggestion_data(suggestion)
      stimulus_action({ click: "accept" }, suggestion_params(suggestion).slice(:text))
    end

    def instructions_data
      stimulus_merge(stimulus_controller("f-input-autosize", inline: true),
                     stimulus_target("instructions"))
    end

    def regenerate_data
      stimulus_action(click: "regenerate")
    end

    def suggestions
      Array(@result.suggestions)
    end

    def suggestion_params(suggestion)
      {
        text: suggestion.text,
        key: suggestion.key,
      }.compact
    end

    def successful?
      @result.success? && suggestions.present?
    end

    def panel_error_class
      return if loading?

      "f-ai-c-text-suggestions__panel--error" unless successful?
    end

    def status_message
      return loading_text if loading?

      if successful?
        warning_messages.presence
      else
        error_message
      end
    end

    def status_hidden?
      status_message.blank?
    end

    def status_icon
      :alert unless loading?
    end

    def panel_title
      I18n.t("folio.ai.console.text_suggestions_component.panel_title_with_field",
             field: @field_label)
    end

    def close_label
      text_suggestions_label(:close_label)
    end

    def copy_label
      text_suggestions_label(:copy_label)
    end

    def copy_button_label
      text_suggestions_label(:copy_button_label)
    end

    def accept_label
      text_suggestions_label(:accept_label)
    end

    def accept_button_label
      text_suggestions_label(:accept_button_label)
    end

    def chars_label
      text_suggestions_label(:chars_label)
    end

    def instructions_placeholder
      text_suggestions_label(:instructions_placeholder)
    end

    def regenerate_label
      text_suggestions_label(:regenerate_label)
    end

    def loading_text
      text_suggestions_label(:loading_text)
    end

    def instructions
      @result.user_instruction.to_s
    end

    def suggestion_tone_label(suggestion)
      suggestion.meta[:tone_label] || suggestion.meta["tone_label"] ||
        suggestion.meta[:toneLabel] || suggestion.meta["toneLabel"]
    end

    def suggestion_over_limit?(suggestion)
      suggestion.meta[:over_limit] || suggestion.meta["over_limit"] ||
        suggestion.meta[:overLimit] || suggestion.meta["overLimit"]
    end

    def character_limit
      @result.field&.character_limit
    end

    def error_message
      I18n.t("folio.ai.console.errors.#{public_error_code}",
             default: text_suggestions_label(:generic_error_text))
    end

    def public_error_code
      return :feature_disabled if @result.error_code == :global_disabled
      return :provider_error if @result.error_code.blank?

      @result.error_code
    end

    def warning_messages
      Array(@result.warnings).filter_map do |warning|
        warning = warning.symbolize_keys
        I18n.t("folio.ai.console.warnings.#{warning[:code]}",
               requested_model: warning[:requested_model],
               fallback_model: warning[:fallback_model],
               default: nil)
      end.join(" ")
    end

    def text_suggestions_label(key)
      I18n.t(key, scope: "folio.ai.console.text_suggestions_component")
    end

    def loading?
      @loading
    end
end

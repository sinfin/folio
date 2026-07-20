# frozen_string_literal: true

# Renders the console suggestion panel for loading, success, and error states.

class Folio::Ai::Console::TextSuggestionsComponent < Folio::Console::ApplicationComponent
  def initialize(component_id:,
                 field:,
                 suggestions: [],
                 instructions: nil,
                 loading: false,
                 error_code: nil,
                 show_instructions: true,
                 show_close: true,
                 grouped: false,
                 loading_suggestion_count: Folio::Ai::DEFAULT_SUGGESTION_COUNT)
    @component_id = component_id
    @field = field.to_h.symbolize_keys
    @suggestions = Array(suggestions).map { |suggestion| suggestion.to_h.symbolize_keys }
    @instructions = instructions.to_s
    @loading = loading
    @error_code = error_code&.to_sym
    @show_instructions = show_instructions
    @show_close = show_close
    @grouped = grouped
    @loading_suggestion_count = loading_suggestion_count.to_i
  end

  private
    def class_name
      "f-ai-c-text-suggestions--grouped" if grouped?
    end

    def component_data
      stimulus_controller("f-ai-c-text-suggestions",
                          values: {
                            key: @field[:key],
                            component_id: @component_id,
                            grouped: grouped?,
                          }.compact,
                          action: {
                            "f-ai-input:suggestionStale" => "clearSuggestionSelection",
                            "f-ai-input:clientError" => "showClientError",
                          })
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
                     stimulus_target("instructions"),
                     Folio::Console::Form::FooterComponent::AUTOSAVE_DISABLED_DATA)
    end

    def field_label
      @field[:label].presence || @field[:key].to_s.humanize
    end

    def loading?
      @loading
    end

    def grouped?
      @grouped
    end

    def successful?
      !loading? && @error_code.blank? && @suggestions.present?
    end

    def error?
      !loading? && @error_code.present?
    end

    def status_message
      return unless error?

      t(".errors.#{@error_code}")
    end

    def status_hidden?
      status_message.blank?
    end

    def loading_suggestions
      Array.new(@loading_suggestion_count.positive? ? @loading_suggestion_count : Folio::Ai::DEFAULT_SUGGESTION_COUNT)
    end

    def show_instructions?
      @show_instructions && !error?
    end

    def show_close?
      @show_close
    end

    def suggestion_params(suggestion)
      {
        text: suggestion[:text],
        key: suggestion[:key],
      }.compact
    end
end

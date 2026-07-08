# frozen_string_literal: true

# Renders the console suggestion panel for loading, success, and error states.

class Folio::Ai::Console::TextSuggestionsComponent < Folio::Console::ApplicationComponent
  LOADING_SUGGESTION_COUNT = 3

  def initialize(component_id:,
                 field:,
                 suggestions: [],
                 instructions: nil,
                 loading: false,
                 error_code: nil,
                 show_instructions: true,
                 show_close: true)
    @component_id = component_id
    @field = field.to_h.symbolize_keys
    @suggestions = Array(suggestions).map { |suggestion| suggestion.to_h.symbolize_keys }
    @instructions = instructions.to_s
    @loading = loading
    @error_code = error_code&.to_sym
    @show_instructions = show_instructions
    @show_close = show_close
  end

  private
    def component_data
      {
        field_key: @field[:key],
      }.compact
    end

    def panel_title
      t(".panel_title", field: field_label, default: "AI suggestions for %{field}")
    end

    def field_label
      @field[:label].presence || @field[:key].to_s.humanize
    end

    def loading?
      @loading
    end

    def successful?
      !loading? && @error_code.blank? && @suggestions.present?
    end

    def error?
      !loading? && @error_code.present?
    end

    def status_message
      return loading_label if loading?
      return unless error?

      t(".errors.#{@error_code}",
        default: t(".errors.generic", default: "AI suggestions could not be generated."))
    end

    def loading_label
      t(".loading", default: "Preparing suggestions")
    end

    def close_label
      t(".close", default: "Close")
    end

    def accept_label
      t(".accept", default: "Use suggestion")
    end

    def characters_label
      t(".characters", default: "characters")
    end

    def instructions_placeholder
      t(".instructions_placeholder", default: "Optional instructions")
    end

    def regenerate_label
      t(".regenerate", default: "Regenerate")
    end

    def loading_suggestions
      Array.new(LOADING_SUGGESTION_COUNT)
    end

    def show_instructions?
      @show_instructions && !error?
    end

    def show_close?
      @show_close
    end

    def suggestion_data(suggestion)
      {
        text: suggestion[:text],
        key: suggestion[:key],
      }.compact
    end

    def character_count_label(suggestion)
      [
        suggestion[:character_count],
        characters_label,
      ].compact.join(" ")
    end

    def character_limit_label(suggestion)
      return unless suggestion[:over_character_limit] && suggestion[:character_limit].present?

      "> #{suggestion[:character_limit]}"
    end
end

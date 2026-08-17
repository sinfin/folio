# frozen_string_literal: true

# Builds stable DOM ids and suggestion component ids shared by AI inputs and groups.
module Folio::Ai::ComponentIds
  TEXT_SUGGESTIONS_PREFIX = "folio_ai_text_suggestions"

  class << self
    def default_input_id(object_name:, field_key:)
      dom_id_token("#{object_name}_#{field_key}")
    end

    def text_suggestions_component_id(input_id:)
      "#{TEXT_SUGGESTIONS_PREFIX}_#{dom_id_token(input_id)}"
    end

    def default_text_suggestions_component_id(object_name:, field_key:)
      text_suggestions_component_id(input_id: default_input_id(object_name:,
                                                               field_key:))
    end

    def dom_id_token(value)
      value.to_s.tr("[]", "_")
           .gsub(/[^a-zA-Z0-9_-]/, "_")
           .squeeze("_")
           .delete_suffix("_")
    end
  end
end

# frozen_string_literal: true

class Folio::Tiptap::EditorComponent < ApplicationComponent
  def initialize(type:, tiptap_content: nil)
    @tiptap_content = tiptap_content.is_a?(Hash) ? tiptap_content.to_json : ""
    @type = case type
            when :block, :rich_text
              type
            else
              fail ArgumentError, "Invalid type: #{type}. Expected :block or :rich_text."
    end
  end

  def data
    stimulus_controller("f-tiptap-editor",
                        values: {
                          type: @type,
                          tiptap_content: @tiptap_content,
                        })
  end
end

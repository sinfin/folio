# frozen_string_literal: true

class Folio::Tiptap::EditorComponent < ApplicationComponent
  def initialize(type:)
    @type = case type
            when :block, :rich_text
              type
            else
              fail ArgumentError, "Invalid type: #{type}. Expected :block or :rich_text."
    end
  end

  def data
    stimulus_controller("f-tiptap-editor",
                        values: { type: @type },
                        action: {
                          "message@window" => "onWindowMessage"
                        })
  end
end

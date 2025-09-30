# frozen_string_literal: true

module TiptapHelper
  def self.tiptap_text_content(text)
    {
      Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => {
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "type" => "text", "text" => text }] },
        ]
      },
      Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:text] => text,
      Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:word_count] => text.split.size,
      Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:character_count] => text.length,
    }
  end

  private
    def tiptap_text_content(text)
      TiptapHelper.tiptap_text_content(text)
    end
end

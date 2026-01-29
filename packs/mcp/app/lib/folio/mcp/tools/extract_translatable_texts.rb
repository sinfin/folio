# frozen_string_literal: true

module Folio
  module Mcp
    module Tools
      class ExtractTranslatableTexts < Base
        class << self
          def call(tiptap:, server_context:)
            return error_response("No tiptap content provided") if tiptap.blank?

            extractor = Folio::Mcp::TiptapTextExtractor.new(tiptap)
            texts = extractor.extract

            structure_hash = Digest::SHA256.hexdigest(tiptap.to_json)[0..15]

            # Audit
            audit_log(server_context, {
              action: "extract_translatable_texts",
              texts_count: texts.size
            })

            success_response({
              texts: texts,
              total_texts: texts.size,
              structure_hash: structure_hash
            })
          rescue StandardError => e
            error_response("Error extracting texts: #{e.message}")
          end
        end
      end
    end
  end
end

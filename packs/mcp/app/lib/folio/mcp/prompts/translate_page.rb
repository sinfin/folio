# frozen_string_literal: true

module Folio
  module Mcp
    module Prompts
      class TranslatePage
        class << self
          def call(args:, server_context:)
            page_id = args["page_id"]
            source_locale = args["source_locale"]
            target_locale = args["target_locale"]

            instructions = <<~INSTRUCTIONS
              # Translation Workflow

              You are translating page ID #{page_id} from #{source_locale} to #{target_locale}.

              ## Steps:

              1. **Read the page** using tool `get_page` with id #{page_id}
                 - Note the tiptap_content field

              2. **Extract translatable texts** using tool `extract_translatable_texts`
                 - Pass the tiptap_content from step 1
                 - You'll receive a list of texts with context

              3. **Translate the texts**
                 - Translate each text value to #{target_locale}
                 - Keep the same tone and style
                 - Preserve any formatting markers

              4. **Apply translations** using tool `apply_translations`
                 - Pass the original tiptap and your translations
                 - You'll receive the complete translated structure

              5. **Update the page** using tool `update_page`
                 - Set tiptap_content_#{target_locale} to the translated structure (if using locale-specific fields)
                 - Or update locale field if creating a new page variant

              ## Important:
              - DO NOT modify the JSON structure, only text values
              - Keep URLs, IDs, and technical values unchanged
              - The context field helps you understand what you're translating
            INSTRUCTIONS

            MCP::Prompt::Result.new(
              description: "Translation workflow for page #{page_id}",
              messages: [
                MCP::Prompt::Message.new(
                  role: "user",
                  content: MCP::Content::Text.new(instructions)
                )
              ]
            )
          end
        end
      end
    end
  end
end

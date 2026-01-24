# frozen_string_literal: true

module Folio
  module Mcp
    module Prompts
      class CreateContent
        class << self
          def call(args:, server_context:)
            content_type = args["content_type"] || "page"
            schema = Folio::Mcp::TiptapSchemaGenerator.new.generate

            nodes_description = schema[:nodes].map do |name, node|
              "### #{name}\n" \
              "Group: #{node[:group]}\n" \
              "#{node[:description]}\n" \
              "Attributes: #{node[:attributes].keys.join(', ')}\n"
            end.join("\n")

            instructions = <<~INSTRUCTIONS
              # Content Creation Guide

              ## Available Content Blocks

              #{nodes_description}

              ## How to Create Content

              1. **Read the schema** for detailed attribute info:
                 Use resource `folio://tiptap/schema`

              2. **Search for images** you might need:
                 Use resource `folio://files?query=...`

              3. **Create the page/article** with:
                 - Basic metadata (title, slug, perex)
                 - tiptap_content with your chosen blocks

              ## Tiptap JSON Structure

              ```json
              {
                "type": "doc",
                "content": [
                  {
                    "type": "paragraph",
                    "content": [{ "type": "text", "text": "Introduction..." }]
                  },
                  {
                    "type": "heading",
                    "attrs": { "level": 2 },
                    "content": [{ "type": "text", "text": "Section Title" }]
                  }
                ]
              }
              ```

              ## Tips
              - Use standard `paragraph`, `heading`, `bulletList` for basic content
              - Use custom nodes for structured components (cards, galleries)
              - Reference images by ID from file search
            INSTRUCTIONS

            MCP::Prompt::Result.new(
              description: "Content creation guide for #{content_type}",
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

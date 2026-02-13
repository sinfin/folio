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

              You can pass tiptap_content in two formats (the system auto-wraps if needed):

              **Simple format (auto-wrapped):**
              ```json
              {
                "type": "doc",
                "content": [
                  { "type": "paragraph", "content": [{ "type": "text", "text": "Hello" }] }
                ]
              }
              ```

              **Full wrapper format:**
              ```json
              {
                "tiptap_content": {
                  "type": "doc",
                  "content": [
                    { "type": "paragraph", "content": [{ "type": "text", "text": "Hello" }] }
                  ]
                }
              }
              ```

              ## Custom Folio Nodes

              Custom nodes use `folioTiptapNode` wrapper:
              ```json
              {
                "type": "folioTiptapNode",
                "attrs": {
                  "type": "YourApp::Tiptap::Node::Cards::Large",
                  "version": 1,
                  "data": {
                    "title": "Card Title",
                    "content": "{\"type\":\"doc\",\"content\":[...]}",
                    "cover_placement_attributes": { "file_id": 123 }
                  }
                }
              }
              ```

              ## Tips
              - Use standard `paragraph`, `heading`, `bulletList` for basic content
              - Use custom nodes for structured components (cards, galleries)
              - Reference images by ID from file search
              - For images: use `cover_placement_attributes: { file_id: ID }` (singular)
              - For multiple images: use `image_placements_attributes: [{ file_id: ID }, ...]` (plural)
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

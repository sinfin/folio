# frozen_string_literal: true

module Folio
  module Mcp
    module Prompts
      class EditMetadata
        class << self
          def call(args:, server_context:)
            resource_type = args["resource_type"] || "page"
            id = args["id"]

            instructions = <<~INSTRUCTIONS
              # Metadata Editing Guide

              You are editing metadata for #{resource_type} ID #{id}.

              ## Steps:

              1. **Read the current #{resource_type}** using tool `get_#{resource_type}` with id #{id}
                 - Review current title, slug, perex, meta_title, meta_description

              2. **Analyze the content** to understand what the page is about

              3. **Update metadata** using tool `update_#{resource_type}`:
                 - `title`: Main visible title (keep it descriptive and engaging)
                 - `slug`: URL-friendly version of title (use lowercase, hyphens)
                 - `perex`: Short description/teaser (1-2 sentences)
                 - `meta_title`: SEO title (max 60 characters, include keywords)
                 - `meta_description`: SEO description (max 160 characters, compelling summary)

              ## SEO Best Practices:
              - Include primary keyword in meta_title
              - Write meta_description as a call-to-action or value proposition
              - Keep slug short and keyword-rich
              - Ensure title is unique across the site
            INSTRUCTIONS

            MCP::Prompt::Result.new(
              description: "Metadata editing guide for #{resource_type} #{id}",
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

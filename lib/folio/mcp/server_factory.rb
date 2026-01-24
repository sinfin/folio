# frozen_string_literal: true

require "mcp"

module Folio
  module Mcp
    class ServerFactory
      class << self
        def build(current_mcp_user:, site:)
          # Ensure all MCP components are loaded
          Folio::Mcp.load_components!

          server_context = {
            user: current_mcp_user,
            site: site,
            audit_logger: Folio::Mcp.configuration.audit_logger
          }

          # Build tools list
          tools = build_tools(server_context)

          # Build resources list
          resources = build_resources(server_context)

          server = MCP::Server.new(
            name: "folio-mcp",
            version: Folio::VERSION,
            tools: tools,
            resources: resources,
            server_context: server_context
          )

          # Register resource read handler
          server.resources_read_handler do |params|
            Folio::Mcp::Resources::Handler.read(
              uri: params[:uri],
              server_context: server_context
            )
          end

          # Register prompts
          register_prompts(server, server_context)

          server
        end

        private
          def build_tools(server_context)
            tools = []
            config = Folio::Mcp.configuration

            config.resources.each do |resource_name, resource_config|
              next unless resource_config[:model]

              tools.concat(build_crud_tools(server_context, resource_name, resource_config))
            end

            # Translation tools
            tools.concat(build_translation_tools(server_context))

            # File upload tool
            if config.resources[:files]&.dig(:uploadable)
              tools << build_file_upload_tool(server_context)
            end

            tools.compact
          end

          def build_crud_tools(server_context, resource_name, resource_config)
            tools = []
            singular_name = resource_name.to_s.singularize

            # Read tool
            if resource_config[:allowed_actions]&.include?(:read)
              tools << MCP::Tool.define(
                name: "get_#{singular_name}",
                description: "Get a #{singular_name} by ID",
                input_schema: {
                  properties: {
                    id: { type: "integer", description: "#{singular_name.titleize} ID" }
                  },
                  required: ["id"]
                }
              ) do |server_context:, **kwargs|
                Folio::Mcp::Tools::GetRecord.call(
                  resource_name: resource_name,
                  id: kwargs[:id],
                  server_context: server_context
                )
              end

              # List tool
              tools << MCP::Tool.define(
                name: "list_#{resource_name}",
                description: "List #{resource_name} with optional filters",
                input_schema: {
                  properties: {
                    limit: { type: "integer", description: "Maximum number of results (default: 50)" },
                    offset: { type: "integer", description: "Offset for pagination" },
                    locale: { type: "string", description: "Filter by locale" },
                    published: { type: "boolean", description: "Filter by published status" }
                  }
                }
              ) do |server_context:, **kwargs|
                Folio::Mcp::Tools::ListRecords.call(
                  resource_name: resource_name,
                  server_context: server_context,
                  **kwargs
                )
              end
            end

            # Create tool
            if resource_config[:allowed_actions]&.include?(:create)
              properties = build_input_properties(resource_config)

              tools << MCP::Tool.define(
                name: "create_#{singular_name}",
                description: "Create a new #{singular_name}",
                input_schema: {
                  properties: properties
                }
              ) do |server_context:, **kwargs|
                Folio::Mcp::Tools::CreateRecord.call(
                  resource_name: resource_name,
                  server_context: server_context,
                  **kwargs
                )
              end
            end

            # Update tool
            if resource_config[:allowed_actions]&.include?(:update)
              properties = build_input_properties(resource_config)
              properties[:id] = { type: "integer", description: "#{singular_name.titleize} ID" }

              tools << MCP::Tool.define(
                name: "update_#{singular_name}",
                description: "Update an existing #{singular_name}. Only provided fields will be changed.",
                input_schema: {
                  properties: properties,
                  required: ["id"]
                }
              ) do |server_context:, **kwargs|
                Folio::Mcp::Tools::UpdateRecord.call(
                  resource_name: resource_name,
                  server_context: server_context,
                  **kwargs
                )
              end
            end

            tools
          end

          def build_translation_tools(server_context)
            [
              MCP::Tool.define(
                name: "extract_translatable_texts",
                description: "Extract translatable text fields from a Tiptap JSON structure for translation",
                input_schema: {
                  properties: {
                    tiptap: { type: "object", description: "Tiptap JSON content to extract texts from" }
                  },
                  required: ["tiptap"]
                }
              ) do |server_context:, **kwargs|
                Folio::Mcp::Tools::ExtractTranslatableTexts.call(
                  tiptap: kwargs[:tiptap],
                  server_context: server_context
                )
              end,

              MCP::Tool.define(
                name: "apply_translations",
                description: "Apply translated texts back to a Tiptap JSON structure",
                input_schema: {
                  properties: {
                    original_tiptap: { type: "object", description: "Original Tiptap JSON structure" },
                    translations: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          path: { type: "string" },
                          value: { type: "string" }
                        }
                      },
                      description: "Array of translations with path and translated value"
                    },
                    structure_hash: { type: "string", description: "Hash from extract_translatable_texts for validation" }
                  },
                  required: ["original_tiptap", "translations"]
                }
              ) do |server_context:, **kwargs|
                Folio::Mcp::Tools::ApplyTranslations.call(
                  original_tiptap: kwargs[:original_tiptap],
                  translations: kwargs[:translations],
                  structure_hash: kwargs[:structure_hash],
                  server_context: server_context
                )
              end
            ]
          end

          def build_file_upload_tool(server_context)
            MCP::Tool.define(
              name: "upload_file",
              description: "Upload a file from URL to the media library",
              input_schema: {
                properties: {
                  url: { type: "string", description: "URL to download file from" },
                  alt: { type: "string", description: "Alt text for images" },
                  title: { type: "string", description: "Title/caption" },
                  tags: {
                    type: "array",
                    items: { type: "string" },
                    description: "Tags for categorization"
                  }
                },
                required: ["url"]
              }
            ) do |server_context:, **kwargs|
              Folio::Mcp::Tools::UploadFile.call(
                server_context: server_context,
                **kwargs
              )
            end
          end

          def build_resources(server_context)
            resources = []
            config = Folio::Mcp.configuration

            config.resources.each do |resource_name, resource_config|
              next unless resource_config[:model]

              resources << MCP::Resource.new(
                uri: "folio://#{resource_name}",
                name: resource_name.to_s,
                description: "List of #{resource_name}",
                mime_type: "application/json"
              )
            end

            # Tiptap schema resource
            resources << MCP::Resource.new(
              uri: "folio://tiptap/schema",
              name: "tiptap-schema",
              description: "Complete schema of available Tiptap nodes",
              mime_type: "application/json"
            )

            resources
          end

          def register_prompts(server, server_context)
            server.define_prompt(
              name: "translate_page",
              description: "Complete workflow for translating a page from one language to another",
              arguments: [
                MCP::Prompt::Argument.new(name: "page_id", description: "ID of the page to translate", required: true),
                MCP::Prompt::Argument.new(name: "source_locale", description: "Source language (cs, en)", required: true),
                MCP::Prompt::Argument.new(name: "target_locale", description: "Target language (cs, en)", required: true)
              ]
            ) do |args, server_context: nil|
              Folio::Mcp::Prompts::TranslatePage.call(args: args, server_context: server_context)
            end

            server.define_prompt(
              name: "create_content",
              description: "Guide for creating new page content with available Tiptap nodes",
              arguments: [
                MCP::Prompt::Argument.new(name: "content_type", description: "Type of content: landing_page, article, service_page", required: false)
              ]
            ) do |args, server_context: nil|
              Folio::Mcp::Prompts::CreateContent.call(args: args, server_context: server_context)
            end

            server.define_prompt(
              name: "edit_metadata",
              description: "Guide for editing SEO and metadata of a page or article",
              arguments: [
                MCP::Prompt::Argument.new(name: "resource_type", description: "Type of resource: page, article, project", required: true),
                MCP::Prompt::Argument.new(name: "id", description: "ID of the resource", required: true)
              ]
            ) do |args, server_context: nil|
              Folio::Mcp::Prompts::EditMetadata.call(args: args, server_context: server_context)
            end
          end

          def build_input_properties(resource_config)
            properties = {}

            (resource_config[:fields] || []).each do |field|
              properties[field] = field_to_json_schema(field)
            end

            (resource_config[:tiptap_fields] || []).each do |field|
              properties[field] = { type: "object", description: "Tiptap JSON content for #{field}" }
            end

            # Add cover_id if cover_field is configured
            if resource_config[:cover_field].present?
              properties[:cover_id] = {
                type: "integer",
                description: "ID of uploaded image file to use as cover (from upload_file tool)"
              }
            end

            properties
          end

          def field_to_json_schema(field)
            case field.to_s
            when /published/, /featured/
              { type: "boolean", description: field.to_s.humanize }
            when /locale/
              { type: "string", enum: Folio::Mcp.configuration.locales.map(&:to_s), description: "Content locale" }
            when /url/, /slug/
              { type: "string", description: field.to_s.humanize }
            else
              { type: "string", description: field.to_s.humanize }
            end
          end
      end
    end
  end
end

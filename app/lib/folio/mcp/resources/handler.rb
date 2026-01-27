# frozen_string_literal: true

module Folio
  module Mcp
    module Resources
      class Handler
        class << self
          def read(uri:, server_context:)
            parsed_uri = parse_uri(uri)
            return error_result("Invalid URI: #{uri}") unless parsed_uri

            case parsed_uri[:type]
            when :list
              read_list(parsed_uri[:resource], server_context)
            when :single
              read_single(parsed_uri[:resource], parsed_uri[:id], server_context)
            when :tiptap_schema
              read_tiptap_schema(server_context)
            when :files_search
              read_files_search(parsed_uri[:params], server_context)
            else
              error_result("Unknown resource type")
            end
          end

          private
            def parse_uri(uri)
              case uri
              when %r{^folio://tiptap/schema$}
                { type: :tiptap_schema }
              when %r{^folio://files\?(.+)$}
                { type: :files_search, params: Rack::Utils.parse_query($1) }
              when %r{^folio://(\w+)/(\d+)$}
                { type: :single, resource: $1.to_sym, id: $2.to_i }
              when %r{^folio://(\w+)$}
                { type: :list, resource: $1.to_sym }
              end
            end

            def read_list(resource_name, server_context)
              config = Folio::Mcp.configuration.resources[resource_name]
              return error_result("Unknown resource: #{resource_name}") unless config

              model_class = config[:model].constantize
              scope = model_class.all

              # Apply site scoping
              if model_class.column_names.include?("site_id")
                scope = scope.where(site: server_context[:site])
              end

              # Apply type filtering
              if config[:allowed_types].present?
                scope = scope.where(type: config[:allowed_types])
              end

              # Limit for resource listing
              records = scope.limit(50)

              serializer = Folio::Mcp::Serializers::RecordList.new(records, config)

              [
                {
                  uri: "folio://#{resource_name}",
                  mimeType: "application/json",
                  text: serializer.as_json.to_json
                }
              ]
            end

            def read_single(resource_name, id, server_context)
              config = Folio::Mcp.configuration.resources[resource_name]
              return error_result("Unknown resource: #{resource_name}") unless config

              model_class = config[:model].constantize
              record = model_class.find_by(id: id)

              return error_result("Record not found") unless record

              serializer = Folio::Mcp::Serializers::Record.new(record, config)

              [
                {
                  uri: "folio://#{resource_name}/#{id}",
                  mimeType: "application/json",
                  text: serializer.as_json.to_json
                }
              ]
            end

            def read_tiptap_schema(server_context)
              schema = Folio::Mcp::TiptapSchemaGenerator.new.generate

              [
                {
                  uri: "folio://tiptap/schema",
                  mimeType: "application/json",
                  text: schema.to_json
                }
              ]
            end

            def read_files_search(params, server_context)
              query = params["query"]
              file_type = params["type"] || "image"
              limit = (params["limit"] || 50).to_i
              offset = (params["offset"] || 0).to_i

              file_class = case file_type
                           when "image" then Folio::File::Image
                           when "document" then Folio::File::Document
                           else Folio::File::Image
              end

              scope = file_class.all

              # Site scoping
              site = server_context[:site]
              scope = scope.where(site: [Folio::File.correct_site(site), site].uniq)

              # Search
              if query.present?
                scope = scope.by_file_name(query) if file_class.respond_to?(:by_file_name)
              end

              files = scope.limit(limit).offset(offset)

              results = files.map do |file|
                {
                  id: file.id,
                  type: file.type,
                  url: file.file&.url,
                  thumbnail_url: file.try(:thumb, "400x300")&.url,
                  filename: file.file_name,
                  alt: file.alt,
                  title: file.title,
                  width: file.try(:file_width),
                  height: file.try(:file_height)
                }
              end

              [
                {
                  uri: "folio://files?query=#{query}",
                  mimeType: "application/json",
                  text: results.to_json
                }
              ]
            end

            def error_result(message)
              # Return empty array for errors - the SDK will handle error responses
              []
            end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Folio
  module Mcp
    module Tools
      class Base
        class << self
          def success_response(data)
            text = data.is_a?(String) ? data : data.to_json
            MCP::Tool::Response.new([{ type: "text", text: text }])
          end

          def error_response(message)
            MCP::Tool::Response.new(
              [{ type: "text", text: { error: message }.to_json }],
              error: true
            )
          end

          def authorize!(user, action, record, resource_config)
            authorize_with = resource_config[:authorize_with]

            case authorize_with
            when :console_ability
              ability = Folio::Ability.new(user, record.try(:site) || user.auth_site)
              unless ability.can?(action, record)
                raise AuthorizationError, "Not authorized to #{action} this record"
              end
            when Proc
              unless authorize_with.call(user, action, record)
                raise AuthorizationError, "Not authorized to #{action} this record"
              end
            end
          end

          def audit_log(server_context, event_data)
            return unless server_context[:audit_logger]

            server_context[:audit_logger].call(event_data.merge(
              user_id: server_context[:user]&.id,
              timestamp: Time.current.iso8601
            ))
          end

          # Tiptap content helpers - shared by CreateRecord and UpdateRecord

          def normalize_tiptap_content(content)
            # Handle string-encoded JSON (workaround for MCP clients that serialize objects as strings)
            if content.is_a?(String) && content.start_with?("{")
              begin
                content = JSON.parse(content)
              rescue JSON::ParserError
                # If parsing fails, return as-is and let validation handle it
                return content
              end
            end

            return content unless content.is_a?(Hash)

            # Deep stringify keys for consistent handling
            content = deep_stringify_keys(content)
            content_key = Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]

            # If already has the wrapper structure, return as is
            if content[content_key].present?
              return content
            end

            # If content looks like a raw tiptap doc (has "type": "doc"), wrap it
            if content["type"] == "doc"
              { content_key => content }
            else
              content
            end
          end

          def validate_tiptap_content(content)
            errors = []

            # Deep stringify keys for consistent handling
            content = deep_stringify_keys(content) if content.is_a?(Hash)
            content_key = Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]

            # Get the actual doc content from wrapper
            actual_content = if content.is_a?(Hash) && content[content_key].present?
              content[content_key]
            else
              content
            end

            return errors unless actual_content.is_a?(Hash)

            # Validate root node type
            root_type = actual_content["type"]
            unless root_type == "doc"
              errors << "Root node must be 'doc', got '#{root_type}'"
              return errors
            end

            # First pass: validate all node types exist (catches silently swallowed errors)
            validate_node_types(actual_content, errors)
            return errors if errors.present?

            # Second pass: extract and validate node attributes
            nodes = Folio::Tiptap::Node.instances_from_tiptap_content(actual_content)

            nodes.each_with_index do |node, index|
              unless node.valid?
                node_type = node.class.name.demodulize
                node.errors.full_messages.each do |msg|
                  errors << "Node ##{index + 1} (#{node_type}): #{msg}"
                end
              end
            end

            errors
          end

          def validate_node_types(content, errors, path = "root")
            return unless content.is_a?(Hash) || content.is_a?(Array)

            if content.is_a?(Array)
              content.each_with_index do |item, index|
                validate_node_types(item, errors, "#{path}[#{index}]")
              end
            elsif content.is_a?(Hash)
              if content["type"] == "folioTiptapNode"
                node_type = content.dig("attrs", "type")
                if node_type.present?
                  klass = node_type.safe_constantize
                  if klass.nil?
                    errors << "Invalid node type at #{path}: '#{node_type}' does not exist"
                  elsif !(klass < Folio::Tiptap::Node)
                    errors << "Invalid node type at #{path}: '#{node_type}' is not a Folio::Tiptap::Node subclass"
                  end
                end
              end

              # Recursively check nested content
              if content["content"].is_a?(Array)
                validate_node_types(content["content"], errors, "#{path}.content")
              end
            end
          end

          def deep_stringify_keys(obj)
            case obj
            when Hash
              obj.each_with_object({}) do |(k, v), result|
                result[k.to_s] = deep_stringify_keys(v)
              end
            when Array
              obj.map { |item| deep_stringify_keys(item) }
            else
              obj
            end
          end
        end
      end

      class AuthorizationError < StandardError; end
    end
  end
end

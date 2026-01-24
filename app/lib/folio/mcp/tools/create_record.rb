# frozen_string_literal: true

module Folio
  module Mcp
    module Tools
      class CreateRecord < Base
        class << self
          def call(resource_name:, server_context:, **attrs)
            config = Folio::Mcp.configuration.resources[resource_name.to_sym]
            return error_response("Unknown resource: #{resource_name}") unless config

            model_class = config[:model].constantize

            # Build new record
            record = model_class.new

            # Set site if model has site
            if model_class.column_names.include?("site_id")
              record.site = server_context[:site]
            end

            # Authorization check
            authorize!(server_context[:user], :create, record, config)

            # Filter allowed attributes
            allowed_attrs = filter_allowed_attrs(attrs, config)
            record.assign_attributes(allowed_attrs)

            # Save
            record.save!

            # Audit
            audit_log(server_context, {
              action: "create_#{resource_name.to_s.singularize}",
              resource_type: resource_name,
              resource_id: record.id,
              attributes: allowed_attrs.keys
            })

            serializer = Folio::Mcp::Serializers::Record.new(record.reload, config)
            success_response(serializer.as_json)
          rescue ActiveRecord::RecordInvalid => e
            error_response("Validation failed: #{e.record.errors.full_messages.join(', ')}")
          rescue Folio::Mcp::Tools::AuthorizationError => e
            error_response(e.message)
          rescue StandardError => e
            error_response("Error: #{e.message}")
          end

          private
            def filter_allowed_attrs(attrs, config)
              allowed_fields = (config[:fields] || []) + (config[:tiptap_fields] || [])
              # MCP sends JSON with string keys, so we need to handle both string and symbol keys
              symbolized_attrs = attrs.transform_keys(&:to_sym)
              symbolized_attrs.slice(*allowed_fields.map(&:to_sym)).compact
            end
        end
      end
    end
  end
end

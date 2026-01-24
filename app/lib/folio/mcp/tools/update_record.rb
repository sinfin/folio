# frozen_string_literal: true

module Folio
  module Mcp
    module Tools
      class UpdateRecord < Base
        class << self
          def call(resource_name:, server_context:, id:, **attrs)
            config = Folio::Mcp.configuration.resources[resource_name.to_sym]
            return error_response("Unknown resource: #{resource_name}") unless config

            model_class = config[:model].constantize
            record = model_class.find(id)

            # Check allowed types
            if config[:allowed_types].present? && !record.type.in?(config[:allowed_types])
              return error_response("Record type not allowed: #{record.type}")
            end

            # Authorization check
            authorize!(server_context[:user], :update, record, config)

            # Filter allowed attributes
            allowed_attrs = filter_allowed_attrs(attrs, config)

            # Update
            record.update!(allowed_attrs)

            # Audit
            audit_log(server_context, {
              action: "update_#{resource_name.to_s.singularize}",
              resource_type: resource_name,
              resource_id: record.id,
              changes: allowed_attrs.keys
            })

            serializer = Folio::Mcp::Serializers::Record.new(record.reload, config)
            success_response(serializer.as_json)
          rescue ActiveRecord::RecordNotFound
            error_response("Record not found: #{resource_name}##{id}")
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
              attrs.slice(*allowed_fields.map(&:to_sym)).compact
            end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Folio
  module Mcp
    module Tools
      class GetRecord < Base
        class << self
          def call(resource_name:, id:, server_context:)
            config = Folio::Mcp.configuration.resources[resource_name.to_sym]
            return error_response("Unknown resource: #{resource_name}") unless config

            model_class = config[:model].constantize
            record = model_class.find_by(id: id)

            return error_response("Record not found: #{resource_name}##{id}") unless record

            # Check allowed types (handle nil type for base classes without STI)
            if config[:allowed_types].present?
              record_type = record.type || record.class.name
              unless record_type.in?(config[:allowed_types])
                return error_response("Record type not allowed: #{record_type}")
              end
            end

            # Authorization
            authorize!(server_context[:user], :read, record, config)

            # Audit
            audit_log(server_context, {
              action: "get_#{resource_name.to_s.singularize}",
              resource_type: resource_name,
              resource_id: record.id
            })

            serializer = Folio::Mcp::Serializers::Record.new(record, config)
            success_response(serializer.as_json)
          rescue ActiveRecord::RecordNotFound
            error_response("Record not found: #{resource_name}##{id}")
          rescue Folio::Mcp::Tools::AuthorizationError => e
            error_response(e.message)
          rescue StandardError => e
            error_response("Error: #{e.message}")
          end
        end
      end
    end
  end
end

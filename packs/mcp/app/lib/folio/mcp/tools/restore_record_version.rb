# frozen_string_literal: true

module Folio
  module Mcp
    module Tools
      class RestoreRecordVersion < Base
        class << self
          def call(resource_name:, id:, version:, server_context:)
            config = Folio::Mcp.configuration.resources[resource_name.to_sym]
            return error_response("Unknown resource: #{resource_name}") unless config
            return error_response("Versioning not enabled for #{resource_name}") unless config[:versioned]
            return error_response("Update action not allowed for #{resource_name}") unless config[:allowed_actions]&.include?(:update)

            model_class = config[:model].constantize

            # Check if model has auditing enabled
            unless model_class.respond_to?(:audited_console_enabled?) && model_class.audited_console_enabled?
              return error_response("Auditing not enabled for #{model_class.name}. Set folio_pages_audited = true in config.")
            end

            record = model_class.find_by(id: id)
            return error_response("Record not found: #{resource_name}##{id}") unless record

            # Authorization - need update permission for restore
            authorize!(server_context[:user], :update, record, config)

            # Find the audit
            audit = record.audits.find_by_version(version)
            return error_response("Version #{version} not found for #{resource_name}##{id}") unless audit

            # Reconstruct the record at that version
            revision = audit.revision

            if revision.try(:type)
              revision = revision.becomes(revision.type.constantize)
            end

            revision.reconstruct_folio_audited_data(audit: audit)

            # Check if restorable
            unless revision.try(:audited_console_restorable?) != false
              return error_response("This version cannot be restored")
            end

            # Save the revision (this creates a new version in audit history)
            revision.save!

            # Audit
            audit_log(server_context, {
              action: "restore_#{resource_name.to_s.singularize}_version",
              resource_type: resource_name,
              resource_id: record.id,
              restored_from_version: version,
              new_version: revision.audits.maximum(:version)
            })

            # Re-serialize the restored record
            restored_record = model_class.find(id)
            serializer = Folio::Mcp::Serializers::Record.new(restored_record, config)

            success_response({
              message: "Successfully restored #{resource_name.to_s.singularize} ##{id} to version #{version}",
              restored_from_version: version,
              new_version: restored_record.audits.maximum(:version),
              record: serializer.as_json
            })
          rescue ActiveRecord::RecordNotFound
            error_response("Record not found: #{resource_name}##{id}")
          rescue Folio::Mcp::Tools::AuthorizationError => e
            error_response(e.message)
          rescue ActiveRecord::RecordInvalid => e
            error_response("Validation failed: #{e.record.errors.full_messages.join(', ')}")
          rescue StandardError => e
            error_response("Error: #{e.message}")
          end
        end
      end
    end
  end
end

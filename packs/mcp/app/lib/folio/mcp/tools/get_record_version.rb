# frozen_string_literal: true

module Folio
  module Mcp
    module Tools
      class GetRecordVersion < Base
        class << self
          def call(resource_name:, id:, version:, server_context:)
            config = Folio::Mcp.configuration.resources[resource_name.to_sym]
            return error_response("Unknown resource: #{resource_name}") unless config
            return error_response("Versioning not enabled for #{resource_name}") unless config[:versioned]

            model_class = config[:model].constantize

            # Check if model has auditing enabled
            unless model_class.respond_to?(:audited_console_enabled?) && model_class.audited_console_enabled?
              return error_response("Auditing not enabled for #{model_class.name}. Set folio_pages_audited = true in config.")
            end

            record = model_class.find_by(id: id)
            return error_response("Record not found: #{resource_name}##{id}") unless record

            # Authorization
            authorize!(server_context[:user], :read, record, config)

            # Find the audit
            audit = record.audits.find_by_version(version)
            return error_response("Version #{version} not found for #{resource_name}##{id}") unless audit

            # Reconstruct the record at that version
            revision = audit.revision

            if revision.try(:type)
              revision = revision.becomes(revision.type.constantize)
            end

            revision.reconstruct_folio_audited_data(audit: audit)

            # Serialize the revision
            serializer = Folio::Mcp::Serializers::Record.new(revision, config)
            serialized = serializer.as_json

            # Add version metadata
            result = {
              version_info: {
                version: audit.version,
                action: audit.action,
                created_at: audit.created_at.iso8601,
                user: audit.user ? { id: audit.user.id, email: audit.user.email } : nil,
                changes: summarize_changes(audit),
                preview_url: build_preview_url(resource_name, record, audit, server_context),
                restorable: revision.try(:audited_console_restorable?) != false
              },
              record: serialized
            }

            # Audit
            audit_log(server_context, {
              action: "get_#{resource_name.to_s.singularize}_version",
              resource_type: resource_name,
              resource_id: record.id,
              version: version
            })

            success_response(result)
          rescue ActiveRecord::RecordNotFound
            error_response("Record not found: #{resource_name}##{id}")
          rescue Folio::Mcp::Tools::AuthorizationError => e
            error_response(e.message)
          rescue StandardError => e
            error_response("Error: #{e.message}")
          end

          private
            def summarize_changes(audit)
              changes = audit.audited_changes || {}
              changed_fields = changes.keys

              if changes["folio_audited_changed_relations"].present?
                changed_fields += changes["folio_audited_changed_relations"].last || []
              end

              changed_fields.uniq - ["folio_audited_changed_relations"]
            end

            def build_preview_url(resource_name, record, audit, server_context)
              site = server_context[:site] || Folio::Current.site
              return nil unless site

              host = site.env_aware_domain
              protocol = Rails.env.development? ? "http" : "https"

              path = revision_path_for(resource_name, record, audit.version)
              return nil unless path

              "#{protocol}://#{host}#{path}"
            end

            def revision_path_for(resource_name, record, version)
              case resource_name.to_sym
              when :pages
                "/folio/console/pages/#{record.id}/revision/#{version}"
              when :projects
                "/folio/console/sinfin_digital/projects/#{record.id}/revision/#{version}"
              else
                nil
              end
            end
        end
      end
    end
  end
end

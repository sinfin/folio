# frozen_string_literal: true

module Folio
  module Mcp
    module Tools
      class ListRecordVersions < Base
        class << self
          def call(resource_name:, id:, server_context:, limit: 20, offset: 0)
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

            # Get audits with pagination
            audits = record.audits
                           .includes(:user)
                           .unscope(:order)
                           .order(version: :desc)
                           .offset(offset)
                           .limit(limit)

            total_count = record.audits.count

            versions = audits.map do |audit|
              {
                version: audit.version,
                action: audit.action,
                created_at: audit.created_at.iso8601,
                user: audit.user ? { id: audit.user.id, email: audit.user.email } : nil,
                changes: summarize_changes(audit),
                preview_url: build_preview_url(resource_name, record, audit, server_context)
              }
            end

            # Audit
            audit_log(server_context, {
              action: "list_#{resource_name.to_s.singularize}_versions",
              resource_type: resource_name,
              resource_id: record.id
            })

            success_response({
              record_id: record.id,
              record_title: record.try(:title) || record.try(:name),
              versions: versions,
              total_count: total_count,
              limit: limit,
              offset: offset
            })
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

              # Add relation changes from folio_audited_changed_relations
              if changes["folio_audited_changed_relations"].present?
                changed_fields += changes["folio_audited_changed_relations"].last || []
              end

              changed_fields.uniq - ["folio_audited_changed_relations"]
            end

            def build_preview_url(resource_name, record, audit, server_context)
              site = server_context[:site] || Folio::Current.site
              return nil unless site

              # Build console revision URL
              host = site.env_aware_domain
              protocol = Rails.env.development? ? "http" : "https"

              # Determine path based on resource type and model class
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
                # Try to generate generic path from model class
                nil
              end
            end
        end
      end
    end
  end
end

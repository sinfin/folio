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

            # Check allowed types (handle nil type for base classes without STI)
            if config[:allowed_types].present?
              record_type = record.type || record.class.name
              unless record_type.in?(config[:allowed_types])
                return error_response("Record type not allowed: #{record_type}")
              end
            end

            # Authorization check
            authorize!(server_context[:user], :update, record, config)

            # Filter allowed attributes
            allowed_attrs = filter_allowed_attrs(attrs, config)

            # Validate tiptap content if present
            tiptap_fields = config[:tiptap_fields] || []
            tiptap_fields.each do |field|
              if allowed_attrs[field.to_sym].present?
                validation_errors = validate_tiptap_content(allowed_attrs[field.to_sym])
                if validation_errors.present?
                  return error_response("Invalid tiptap content in #{field}: #{validation_errors.join('; ')}")
                end
              end
            end

            # Handle cover assignment if cover_id provided and cover_field configured
            if attrs[:cover_id].present? && config[:cover_field].present?
              assign_cover(record, attrs[:cover_id], config[:cover_field], server_context[:site])
            end

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

            def assign_cover(record, file_id, cover_field, site)
              file = Folio::File::Image.find_by(id: file_id, site: site)
              return unless file

              # The cover_field is typically a has_one :through relationship
              # We need to work with the _placement association directly
              placement_name = "#{cover_field}_placement"
              placement_reflection = record.class.reflections[placement_name]
              return unless placement_reflection

              # Remove existing placement and create new one
              record.send(placement_name)&.destroy
              record.send("build_#{placement_name}", file_id: file.id)
            end

            def validate_tiptap_content(content)
              errors = []

              # Handle wrapped structure { locale: "cs", tiptap_content: { type: "doc", ... } }
              actual_content = if content.is_a?(Hash) && content[:tiptap_content].present?
                content[:tiptap_content]
              elsif content.is_a?(Hash) && content["tiptap_content"].present?
                content["tiptap_content"]
              else
                content
              end

              return errors unless actual_content.is_a?(Hash)

              # Extract and validate all tiptap nodes
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
        end
      end
    end
  end
end

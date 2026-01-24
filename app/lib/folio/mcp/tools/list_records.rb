# frozen_string_literal: true

module Folio
  module Mcp
    module Tools
      class ListRecords < Base
        class << self
          def call(resource_name:, server_context:, limit: 50, offset: 0, **filters)
            config = Folio::Mcp.configuration.resources[resource_name.to_sym]
            return error_response("Unknown resource: #{resource_name}") unless config

            model_class = config[:model].constantize
            scope = model_class.all

            # Apply site scoping if model has site
            if model_class.column_names.include?("site_id")
              scope = scope.where(site: server_context[:site])
            end

            # Apply type filtering
            if config[:allowed_types].present?
              scope = scope.where(type: config[:allowed_types])
            end

            # Apply filters
            scope = apply_filters(scope, filters, model_class)

            # Pagination
            total_count = scope.count
            records = scope.limit([limit.to_i, 100].min).offset(offset.to_i)

            # Audit
            audit_log(server_context, {
              action: "list_#{resource_name}",
              resource_type: resource_name,
              filters: filters,
              count: records.size
            })

            serializer = Folio::Mcp::Serializers::RecordList.new(records, config)
            success_response({
              data: serializer.as_json,
              meta: {
                total: total_count,
                limit: limit,
                offset: offset
              }
            })
          rescue StandardError => e
            error_response("Error: #{e.message}")
          end

          private
            def apply_filters(scope, filters, model_class)
              filters.each do |key, value|
                next if value.nil?

                case key.to_s
                when "locale"
                  scope = scope.where(locale: value) if model_class.column_names.include?("locale")
                when "published"
                  if model_class.column_names.include?("published")
                    scope = scope.where(published: value)
                  elsif model_class.column_names.include?("published_at")
                    scope = value ? scope.where.not(published_at: nil) : scope.where(published_at: nil)
                  end
                when "type"
                  scope = scope.where(type: value) if model_class.column_names.include?("type")
                end
              end

              scope
            end
        end
      end
    end
  end
end

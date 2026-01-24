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
                raise Folio::Mcp::AuthorizationError, "Not authorized to #{action} this record"
              end
            when Proc
              unless authorize_with.call(user, action, record)
                raise Folio::Mcp::AuthorizationError, "Not authorized to #{action} this record"
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
        end
      end

      class AuthorizationError < StandardError; end
    end
  end
end

# frozen_string_literal: true

module Folio
  module Api
    class McpController < ActionController::API
      before_action :authenticate_mcp_token!
      before_action :check_mcp_enabled!

      def handle
        server = Folio::Mcp::ServerFactory.build(
          current_mcp_user: @current_mcp_user,
          site: current_site
        )

        request_body = request.body.read
        log_mcp_request(request_body)

        response_json = server.handle_json(request_body)

        log_mcp_response(response_json)

        render json: response_json, content_type: "application/json"
      end

      private
        def authenticate_mcp_token!
          token = extract_bearer_token
          return head :unauthorized if token.blank?

          @current_mcp_user = find_user_by_token(token)
          head :unauthorized unless @current_mcp_user
        end

        def extract_bearer_token
          auth_header = request.headers["Authorization"]
          return nil if auth_header.blank?

          auth_header.delete_prefix("Bearer ").strip
        end

        def find_user_by_token(token)
          # First try to find by plain token (for development/testing)
          user = Folio::User.find_by(mcp_api_token: token, mcp_enabled: true)
          return user if user

          # Then try hashed token lookup
          Folio::User.where(mcp_enabled: true).find_each do |u|
            next unless u.mcp_api_token_digest.present?

            if secure_compare_token(token, u.mcp_api_token_digest)
              return u
            end
          end

          nil
        end

        def secure_compare_token(token, digest)
          BCrypt::Password.new(digest) == token
        rescue BCrypt::Errors::InvalidHash
          false
        end

        def check_mcp_enabled!
          head :not_found unless Folio::Mcp.enabled?
        end

        def current_site
          @current_mcp_user&.auth_site || Folio::Current.site
        end

        def log_mcp_request(body)
          return unless Folio::Mcp.configuration.audit_logger

          parsed = JSON.parse(body) rescue {}

          Folio::Mcp.configuration.audit_logger.call({
            type: "request",
            user_id: @current_mcp_user&.id,
            user_email: @current_mcp_user&.email,
            method: parsed["method"],
            params: parsed["params"],
            timestamp: Time.current.iso8601
          })
        end

        def log_mcp_response(response)
          return unless Folio::Mcp.configuration.audit_logger

          parsed = JSON.parse(response) rescue {}

          Folio::Mcp.configuration.audit_logger.call({
            type: "response",
            user_id: @current_mcp_user&.id,
            has_error: parsed["error"].present?,
            timestamp: Time.current.iso8601
          })
        end
    end
  end
end

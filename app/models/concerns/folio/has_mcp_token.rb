# frozen_string_literal: true

require "bcrypt"

module Folio::HasMcpToken
  extend ActiveSupport::Concern

  MCP_TOKEN_PREFIX = "mcp_live_"

  included do
    scope :mcp_enabled, -> { where(mcp_enabled: true) }
  end

  def regenerate_mcp_api_token!
    token = generate_mcp_token
    digest = BCrypt::Password.create(token)

    update!(
      mcp_api_token: token,
      mcp_api_token_digest: digest,
      mcp_enabled: true,
      mcp_token_created_at: Time.current
    )

    token
  end

  def revoke_mcp_api_token!
    update!(
      mcp_api_token: nil,
      mcp_api_token_digest: nil,
      mcp_enabled: false
    )
  end

  def mcp_token_active?
    mcp_enabled? && mcp_api_token.present?
  end

  def record_mcp_token_usage!
    update_column(:mcp_token_last_used_at, Time.current)
  end

  private
    def generate_mcp_token
      "#{MCP_TOKEN_PREFIX}#{SecureRandom.hex(32)}"
    end
end

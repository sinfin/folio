# frozen_string_literal: true

namespace :folio do
  namespace :mcp do
    desc "Generate MCP API token for a user. Usage: rails folio:mcp:generate_token[email@example.com]"
    task :generate_token, [:email] => :environment do |_t, args|
      email = args[:email]

      if email.blank?
        puts "Usage: rails folio:mcp:generate_token[email@example.com]"
        exit 1
      end

      user = Folio::User.find_by(email: email)

      unless user
        puts "User not found: #{email}"
        exit 1
      end

      token = user.regenerate_mcp_api_token!

      puts ""
      puts "=" * 60
      puts "MCP API token generated for #{user.email}"
      puts "=" * 60
      puts ""
      puts "Token (save this - it won't be shown again):"
      puts token
      puts ""
      puts "Add to your .cursor/mcp.json:"
      puts ""
      puts JSON.pretty_generate({
        "mcpServers" => {
          "folio-local" => {
            "type" => "http",
            "url" => "http://localhost:3000/folio/api/mcp",
            "headers" => {
              "Authorization" => "Bearer #{token}"
            }
          }
        }
      })
      puts ""
    end

    desc "List users with MCP enabled"
    task list_enabled: :environment do
      users = Folio::User.where(mcp_enabled: true)

      if users.empty?
        puts "No users with MCP enabled."
      else
        puts "Users with MCP enabled:"
        puts "-" * 60
        users.each do |user|
          last_used = user.mcp_token_last_used_at&.strftime("%Y-%m-%d %H:%M") || "never"
          puts "#{user.email} - last used: #{last_used}"
        end
      end
    end

    desc "Disable MCP for a user. Usage: rails folio:mcp:disable[email@example.com]"
    task :disable, [:email] => :environment do |_t, args|
      email = args[:email]

      if email.blank?
        puts "Usage: rails folio:mcp:disable[email@example.com]"
        exit 1
      end

      user = Folio::User.find_by(email: email)

      unless user
        puts "User not found: #{email}"
        exit 1
      end

      user.update!(
        mcp_enabled: false,
        mcp_api_token: nil,
        mcp_api_token_digest: nil
      )

      puts "MCP disabled for #{user.email}"
    end
  end
end

# frozen_string_literal: true

require "test_helper"
require "ostruct"

require Folio::Engine.root.join("packs/mcp/lib/folio/mcp")
require Folio::Engine.root.join("packs/mcp/app/controllers/folio/api/mcp_controller")

class Folio::Api::McpControllerTest < ActionController::TestCase
  tests Folio::Api::McpController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw { post "mcp" => "folio/api/mcp#handle" }
  end

  test "acknowledges initialized notification without JSON body" do
    server = Minitest::Mock.new
    server.expect(:handle_json, nil, [String])

    Folio::User.stub(:find_by, OpenStruct.new(auth_site: nil)) do
      Folio::Mcp::ServerFactory.stub(:build, server) do
        @request.headers["Authorization"] = "Bearer mcp-token"
        @request.headers["Content-Type"] = "application/json"
        @request.headers["Accept"] = "application/json, text/event-stream"
        @request.headers["MCP-Protocol-Version"] = "2025-06-18"
        post :handle, body: {
          jsonrpc: "2.0",
          method: "notifications/initialized",
        }.to_json
      end
    end

    assert_response :accepted
    assert_empty response.body
    server.verify
  end
end

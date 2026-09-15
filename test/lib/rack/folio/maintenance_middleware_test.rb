# frozen_string_literal: true

require "test_helper"

class Folio::MaintenanceMiddlewareTest < ActiveSupport::TestCase
  test "middleware returns lowercase response header names" do
    Rack::Folio::MaintenanceMiddleware.stub(:maintenance_html, "<p>Maintenance</p>") do
      headers = Rack::Folio::MaintenanceMiddleware.new(nil).render_maintenance_html[1]

      assert_equal({ "content-type" => "text/html" }, headers)
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class Folio::SidekiqWebTest < Folio::BaseControllerTest
  test "superadmin opens the scheduled jobs in the Sidekiq web UI" do
    get "/sidekiq/cron"

    assert_response :success
  end
end

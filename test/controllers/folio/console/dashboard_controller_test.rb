# frozen_string_literal: true

require 'test_helper'
require_relative 'base_controller_test'

module Folio
  class Console::DashboardControllerTest < Console::BaseControllerTest
    include Engine.routes.url_helpers

    test 'should or should not get index' do
      get console_root_url
      assert_response :success

      sign_out @admin
      get console_root_url
      assert_response :redirect
    end
  end
end

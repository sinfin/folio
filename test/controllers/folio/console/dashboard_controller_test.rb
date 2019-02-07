# frozen_string_literal: true

require 'test_helper'

module Folio
  class Console::DashboardControllerTest < Console::BaseControllerTest
    include Engine.routes.url_helpers

    test 'should or should not get index' do
      get console_root_url
      assert_redirected_to console_pages_path

      @admin.forget_me!
      sign_out @admin
      get console_root_url
      assert_redirected_to new_account_session_path
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

module Folio
  class Console::BaseControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include Engine.routes.url_helpers

    setup do
      create(:site)
      @admin = create(:admin_account)
      sign_in @admin
    end

    # test "the truth" do
    #   assert true
    # end
  end
end

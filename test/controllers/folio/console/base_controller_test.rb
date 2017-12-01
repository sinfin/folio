# frozen_string_literal: true

require 'test_helper'

module Folio
  class Console::BaseControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include Engine.routes.url_helpers

    setup do
      create(:folio_site)
      @admin = create(:folio_admin_account)
      sign_in @admin
    end

    # test "the truth" do
    #   assert true
    # end
  end
end

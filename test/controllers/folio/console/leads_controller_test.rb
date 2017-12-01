# frozen_string_literal: true

require 'test_helper'

module Folio
  class Console::LeadsControllerTest < Folio::Console::BaseControllerTest
    include Engine.routes.url_helpers

    setup do
      @lead = create(:folio_lead)
    end

    test 'should get index' do
      get console_leads_url
      assert_response :success
    end

    test 'should get edit' do
      get edit_console_lead_url(@lead)
      assert_response :success
    end
  end
end

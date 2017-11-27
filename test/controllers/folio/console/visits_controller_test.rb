# frozen_string_literal: true

require 'test_helper'

module Folio
  class Console::VisitsControllerTest < Folio::Console::BaseControllerTest
    include Engine.routes.url_helpers

    test 'should get index' do
      get console_visits_url
      assert_response :success
    end
  end
end

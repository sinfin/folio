# frozen_string_literal: true

require "test_helper"

module Folio
  class CsrfControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "show" do
      get csrf_path
      assert_response(:ok)
      assert response.body.present?
    end
  end
end

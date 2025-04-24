# frozen_string_literal: true

require "test_helper"

class Folio::ErrorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_and_host_site
  end

  test "should get 404" do
    get "/404"
    assert_response :not_found
    assert_equal "no-store", response.get_header("Cache-Control")
    assert_select "h1", "404"
  end

  test "should get 500" do
    get "/500"
    assert_response :internal_server_error
    assert_equal "no-store", response.get_header("Cache-Control")
    assert_select "h1", "500"
  end

  test "should get 403" do
    get "/403"
    assert_response :forbidden
    assert_equal "no-store", response.get_header("Cache-Control")
    assert_select "h1", "403"
  end
end

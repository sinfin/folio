# frozen_string_literal: true

require "test_helper"

class Folio::RobotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_and_host_site
  end

  test "returns text/plain content type" do
    get "/robots.txt"

    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.content_type
  end

  test "includes sitemap url" do
    get "/robots.txt"

    assert_response :success
    assert_match(/^Sitemap:/, response.body)
  end
end


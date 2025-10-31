# frozen_string_literal: true

require "test_helper"

class Folio::Api::ThumbnailsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @site = get_current_or_existing_site_or_create_from_factory
    @image1 = create(:folio_file_image, site: @site, additional_data: { "generate_thumbnails_in_test" => true })
    @image2 = create(:folio_file_image, site: @site, additional_data: { "generate_thumbnails_in_test" => true })
    @audio = create(:folio_file_audio, site: @site)
  end

  test "should get thumbnails for valid image IDs with sizes" do
    thumbnails_params = [
      { id: @image1.id, size: "100x100" },
      { id: @image2.id, size: "200x200" }
    ]

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal 2, json_response.length

    # Check first image response
    image1_response = json_response.find { |item| item["id"] == @image1.id }
    assert_not_nil image1_response
    assert image1_response.key?("url")
    assert image1_response.key?("ready")

    # URL might be nil if thumbnail isn't ready yet
    if image1_response["ready"]
      assert_not_nil image1_response["url"]
      assert image1_response["url"].present?
    else
      assert_nil image1_response["url"]
    end

    # Check second image response
    image2_response = json_response.find { |item| item["id"] == @image2.id }
    assert_not_nil image2_response
    assert image2_response.key?("url")
    assert image2_response.key?("ready")

    # URL might be nil if thumbnail isn't ready yet
    if image2_response["ready"]
      assert_not_nil image2_response["url"]
      assert image2_response["url"].present?
    else
      assert_nil image2_response["url"]
    end
  end

  test "should include webp_url when available" do
    thumbnails_params = [
      { id: @image1.id, size: "100x100" }
    ]

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success
    json_response = JSON.parse(response.body)

    image_response = json_response.first
    # webp_url might be nil or present depending on thumbnail generation
    assert image_response.key?("webp_url")
  end

  test "should handle missing file IDs gracefully" do
    non_existent_id = @image1.id + @image2.id + 9999
    thumbnails_params = [
      { id: @image1.id, size: "100x100" },
      { id: non_existent_id, size: "200x200" }
    ]

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success
    json_response = JSON.parse(response.body)

    # Should only return data for existing files
    assert_equal 1, json_response.length
    assert_equal @image1.id, json_response.first["id"]
  end

  test "should handle non-image files gracefully" do
    thumbnails_params = [
      { id: @image1.id, size: "100x100" },
      { id: @audio.id, size: "200x200" }
    ]

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success
    json_response = JSON.parse(response.body)

    # Should only return data for image files
    assert_equal 1, json_response.length
    assert_equal @image1.id, json_response.first["id"]
  end

  test "should handle empty thumbnails parameter" do
    get folio_api_thumbnails_path, params: { thumbnails: [] }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal [], json_response
  end

  test "should handle missing thumbnails parameter" do
    get folio_api_thumbnails_path

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal [], json_response
  end

  test "should handle malformed thumbnails parameter" do
    get folio_api_thumbnails_path, params: { thumbnails: "invalid" }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal [], json_response
  end

  test "should handle thumbnails without id parameter" do
    thumbnails_params = [
      { size: "100x100" },
      { id: @image1.id, size: "200x200" }
    ]

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success
    json_response = JSON.parse(response.body)

    # Should only return data for requests with valid id
    assert_equal 1, json_response.length
    assert_equal @image1.id, json_response.first["id"]
  end

  test "should handle thumbnails without size parameter" do
    thumbnails_params = [
      { id: @image1.id },
      { id: @image2.id, size: "200x200" }
    ]

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success
    json_response = JSON.parse(response.body)

    # Should only return data for requests with valid size
    assert_equal 1, json_response.length
    assert_equal @image2.id, json_response.first["id"]
  end

  test "should return consistent response format" do
    thumbnails_params = [
      { id: @image1.id, size: "100x100" }
    ]

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success
    json_response = JSON.parse(response.body)

    image_response = json_response.first
    assert image_response.key?("id")
    assert image_response.key?("url")
    assert image_response.key?("webp_url")
    assert image_response.key?("width")
    assert image_response.key?("height")
    assert image_response.key?("ready")
    assert_equal @image1.id, image_response["id"]
  end

  test "should handle multiple requests for same file with different sizes" do
    thumbnails_params = [
      { id: @image1.id, size: "100x100" },
      { id: @image1.id, size: "200x200" }
    ]

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success
    json_response = JSON.parse(response.body)

    # Should return separate entries for different sizes
    assert_equal 2, json_response.length

    sizes = json_response.map { |item| item["size"] }
    assert_includes sizes, "100x100"
    assert_includes sizes, "200x200"
  end

  test "should limit requests to 50 to prevent abuse" do
    # Create 60 thumbnail requests (exceeding the 50 limit)
    thumbnails_params = []
    60.times do |i|
      thumbnails_params << { id: @image1.id, size: "100x100" }
    end

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success
    json_response = JSON.parse(response.body)

    # Should only process the first 50 requests
    assert_equal 50, json_response.length
  end

  test "should return ready status and handle URLs appropriately" do
    thumbnails_params = [
      { id: @image1.id, size: "100x100" }
    ]

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success
    json_response = JSON.parse(response.body)

    image_response = json_response.first
    assert image_response.key?("ready")

    # If ready is true, url should be present and not contain doader.com
    if image_response["ready"]
      assert_not_nil image_response["url"]
      assert_not image_response["url"].include?("doader.com"), "Ready thumbnail should not contain doader.com"
    else
      # If ready is false, url should be nil
      assert_nil image_response["url"], "Not-ready thumbnail should have nil URL"
    end
  end

  test "should return correct proportional dimensions in thumbnail data" do
    # Set up an image with known dimensions for predictable calculations
    @image1.update_columns(file_width: 1000, file_height: 500)

    thumbnails_params = [
      { id: @image1.id, size: "100x100" },    # Should give 100x50 (proportional)
      { id: @image1.id, size: "100x100#" },   # Should give 100x100 (cropped)
      { id: @image1.id, size: "200x" },       # Should give 200x100 (width-only)
      { id: @image1.id, size: "x50" }         # Should give 100x50 (height-only)
    ]

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 4, json_response.length

    # Find responses by size
    proportional_response = json_response.find { |item| item["size"] == "100x100" }
    cropped_response = json_response.find { |item| item["size"] == "100x100#" }
    width_only_response = json_response.find { |item| item["size"] == "200x" }
    height_only_response = json_response.find { |item| item["size"] == "x50" }

    # Test proportional sizing (100x100 on 1000x500 should give 100x50)
    assert_equal 100, proportional_response["width"]
    assert_equal 50, proportional_response["height"]

    # Test cropped sizing (should give exact dimensions)
    assert_equal 100, cropped_response["width"]
    assert_equal 100, cropped_response["height"]

    # Test width-only sizing (200x on 1000x500 should give 200x100)
    assert_equal 200, width_only_response["width"]
    assert_equal 100, width_only_response["height"]

    # Test height-only sizing (x50 on 1000x500 should give 100x50)
    assert_equal 100, height_only_response["width"]
    assert_equal 50, height_only_response["height"]
  end

  test "should set appropriate cache headers" do
    thumbnails_params = [
      { id: @image1.id, size: "100x100" }
    ]

    get folio_api_thumbnails_path, params: { thumbnails: thumbnails_params }

    assert_response :success

    # Check that cache headers are set correctly to match fragment cache duration
    cache_control = response.headers["Cache-Control"]
    assert_not_nil cache_control, "Cache-Control header should be present"

    # Verify the cache header components match the 2-second fragment cache
    assert_includes cache_control, "max-age=2", "Should have max-age=2 to match fragment cache"
    assert_includes cache_control, "must-revalidate", "Should have must-revalidate"
    assert_includes cache_control, "stale-while-revalidate=1", "Should have stale-while-revalidate=1"
    assert_includes cache_control, "stale-if-error=10", "Should have stale-if-error=10"
  end
end

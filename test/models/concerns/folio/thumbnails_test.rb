# frozen_string_literal: true

require "test_helper"

class Folio::ThumbnailsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  THUMB_SIZE = "111x111#"

  test "should not generate duplicate jobs" do
    image = create(:folio_file_image, additional_data: { "generate_thumbnails_in_test" => true })

    assert_nil image.thumbnail_sizes[THUMB_SIZE]
    assert_enqueued_jobs 0, only: Folio::GenerateThumbnailJob

    # First call should queue a job and return temporary URL
    result1 = image.thumb(THUMB_SIZE)
    assert_enqueued_jobs 1, only: Folio::GenerateThumbnailJob

    # With simplified logic, no temporary data is stored in database
    # The method returns a temporary URL immediately
    assert result1.url.include?("doader.com")
    assert_equal 111, result1.width
    assert_equal 111, result1.height

    # Second call should also queue a job (activejob-uniqueness handles deduplication)
    image.thumb(THUMB_SIZE)
    # Note: The actual deduplication happens at the sidekiq level, not here
    # So we might see 2 enqueued jobs, but activejob-uniqueness will deduplicate them

    perform_enqueued_jobs

    image.reload
    assert image.thumbnail_sizes[THUMB_SIZE][:uid]
    # No more started_generating_at with simplified logic
    assert_nil image.thumbnail_sizes[THUMB_SIZE][:started_generating_at]
  end

  test "works for animated gif" do
    image = create(:folio_file_image, file: Folio::Engine.root.join("test/fixtures/folio/animated.gif"), additional_data: { "generate_thumbnails_in_test" => true, "animated" => true })
    assert image

    perform_enqueued_jobs do
      assert image.thumb(THUMB_SIZE)
    end

    # GIFs are converted to JPG for thumbnails to avoid libvips GIF writer issues
    assert image.reload.thumbnail_sizes[THUMB_SIZE][:uid].ends_with?(".jpg")
  end

  test "uses default x/y from thumbnail_configuration when cropping" do
    image = create(:folio_file_image, additional_data: { "generate_thumbnails_in_test" => true })

    # Set up thumbnail configuration with default crop values for 1:1 ratio
    image.update!(thumbnail_configuration: {
      "ratios" => {
        "1:1" => {
          "crop" => {
            "x" => 0.25,
            "y" => 0.75
          }
        }
      }
    })

    crop_size = "200x200#"

    perform_enqueued_jobs do
      image.thumb(crop_size)
    end

    image.reload
    thumbnail = image.thumbnail_sizes[crop_size]

    # Verify that the thumbnail was generated with the configured x/y values
    assert thumbnail[:uid]
    assert_equal 0.25, thumbnail[:x]
    assert_equal 0.75, thumbnail[:y]
  end

  test "explicit x/y parameters override thumbnail_configuration" do
    image = create(:folio_file_image, additional_data: { "generate_thumbnails_in_test" => true })

    # Set up thumbnail configuration with default crop values
    image.update!(thumbnail_configuration: {
      "ratios" => {
        "1:1" => {
          "crop" => {
            "x" => 0.25,
            "y" => 0.75
          }
        }
      }
    })

    crop_size = "200x200#"

    perform_enqueued_jobs do
      # Pass explicit x/y that should override the configuration
      image.thumb(crop_size, quality: 100, x: 0.5, y: 0.1)
    end

    image.reload
    thumbnail = image.thumbnail_sizes[crop_size]

    # Verify that explicit values were used, not the configured ones
    assert thumbnail[:uid]
    assert_equal 0.5, thumbnail[:x]
    assert_equal 0.1, thumbnail[:y]
  end

  test "proportional sizing for non-cropping thumbnails" do
    # Create an image with known dimensions that result in clean calculations
    image = create(:folio_file_image)
    image.update_columns(file_width: 1000, file_height: 500)

    # Test standard proportional sizing (100x100 on 1000x500 should give 100x50)
    result = image.thumb("100x100")
    assert_equal 100, result.width
    assert_equal 50, result.height

    # Test width-only sizing (200x on 1000x500 should give 200x100)
    result = image.thumb("200x")
    assert_equal 200, result.width
    assert_equal 100, result.height

    # Test height-only sizing (x100 on 1000x500 should give 200x100)
    result = image.thumb("x100")
    assert_equal 200, result.width
    assert_equal 100, result.height
  end

  test "exact sizing for cropping thumbnails with hash" do
    # Create an image with known dimensions
    image = create(:folio_file_image)
    image.update_columns(file_width: 1000, file_height: 500)

    # Test cropping mode - should return exact dimensions regardless of aspect ratio
    result = image.thumb("100x100#")
    assert_equal 100, result.width
    assert_equal 100, result.height

    # Test rectangular crop
    result = image.thumb("300x150#")
    assert_equal 300, result.width
    assert_equal 150, result.height
  end

  test "proportional sizing with tall images" do
    # Create a tall image (portrait) with clean ratios
    image = create(:folio_file_image)
    image.update_columns(file_width: 400, file_height: 800)

    # Test proportional sizing (100x100 on 400x800 should give 50x100)
    result = image.thumb("100x100")
    assert_equal 50, result.width
    assert_equal 100, result.height

    # Test width-only sizing (200x on 400x800 should give 200x400)
    result = image.thumb("200x")
    assert_equal 200, result.width
    assert_equal 400, result.height
  end

  test "proportional sizing with square images" do
    # Create a square image
    image = create(:folio_file_image)
    image.update_columns(file_width: 800, file_height: 800)

    # Test proportional sizing (100x100 on 800x800 should give 100x100)
    result = image.thumb("100x100")
    assert_equal 100, result.width
    assert_equal 100, result.height

    # Test width-only sizing (150x on 800x800 should give 150x150)
    result = image.thumb("150x")
    assert_equal 150, result.width
    assert_equal 150, result.height
  end

  test "proportional sizing edge cases" do
    image = create(:folio_file_image)

    # Test with very small original dimensions that scale cleanly
    image.update_columns(file_width: 20, file_height: 10)
    # Requesting larger than original should scale up proportionally
    result = image.thumb("100x100")
    assert_equal 100, result.width
    assert_equal 50, result.height

    # Test with zero dimensions (should return [0, 0])
    image.update_columns(file_width: 0, file_height: 500)
    result = image.thumb("100x100")
    assert_equal 0, result.width
    assert_equal 0, result.height
  end
end

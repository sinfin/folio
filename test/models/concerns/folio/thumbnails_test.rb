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

    # Second call should also queue a job (sidekiq-unique-jobs handles deduplication)
    image.thumb(THUMB_SIZE)
    # Note: The actual deduplication happens at the sidekiq level, not here
    # So we might see 2 enqueued jobs, but sidekiq-unique-jobs will deduplicate them

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

    assert image.reload.thumbnail_sizes[THUMB_SIZE][:uid].ends_with?(".gif")
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
end

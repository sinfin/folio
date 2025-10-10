# frozen_string_literal: true

require "test_helper"

class Folio::ThumbnailsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  THUMB_SIZE = "111x111#"

  test "should not generate duplicate jobs" do
    image = create(:folio_file_image, additional_data: { "generate_thumbnails_in_test" => true })

    assert_nil image.thumbnail_sizes[THUMB_SIZE]
    assert_enqueued_jobs 0, only: Folio::GenerateThumbnailJob

    image.thumb(THUMB_SIZE)

    assert_enqueued_jobs 1, only: Folio::GenerateThumbnailJob
    started_generating_at = image.thumbnail_sizes[THUMB_SIZE][:started_generating_at]
    assert started_generating_at > 1.hour.ago

    %i[url width height quality].each do |key|
      assert image.thumbnail_sizes[THUMB_SIZE][key]
    end

    image.thumb(THUMB_SIZE)
    assert_enqueued_jobs 1, only: Folio::GenerateThumbnailJob
    %i[url width height quality].each do |key|
      assert image.thumbnail_sizes[THUMB_SIZE][key]
    end
    assert_equal started_generating_at, image.thumbnail_sizes[THUMB_SIZE][:started_generating_at]

    perform_enqueued_jobs

    image.reload
    assert image.thumbnail_sizes[THUMB_SIZE][:uid]
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

# frozen_string_literal: true

require "test_helper"

class Folio::ThumbnailsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  THUMB_SIZE = "111x111#"

  test "should not generate duplicate jobs" do
    image = create(:folio_image)

    assert_nil image.thumbnail_sizes[THUMB_SIZE]
    assert_enqueued_jobs 0, only: Folio::GenerateThumbnailJob

    image.thumb(THUMB_SIZE, override_test_behaviour: true)

    assert_enqueued_jobs 1, only: Folio::GenerateThumbnailJob
    started_generating_at = image.thumbnail_sizes[THUMB_SIZE][:started_generating_at]
    assert started_generating_at > 1.hour.ago

    %i[url width height quality].each do |key|
      assert image.thumbnail_sizes[THUMB_SIZE][key]
    end

    image.thumb(THUMB_SIZE, override_test_behaviour: true)
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
end

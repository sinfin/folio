# frozen_string_literal: true

require "test_helper"

class Folio::PregenerateThumbnailsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  THUMB_SIZE = "100x100"
  THUMB_SIZE_TWO = "110x110"

  class PageWithPregeneratedCover < Folio::Page
    def self.pregenerated_thumbnails
      { "Folio::FilePlacement::Cover" => [THUMB_SIZE, THUMB_SIZE_TWO] }
    end
  end

  test "should pregenerate thumbnails" do
    image = create(:folio_file_image, additional_data: { "generate_thumbnails_in_test" => true })

    assert_nil image.thumbnail_sizes[THUMB_SIZE]
    assert_nil image.thumbnail_sizes[THUMB_SIZE_TWO]

    page = create_page_singleton(PageWithPregeneratedCover)

    # Count jobs enqueued by this specific action - expecting 2 pregenerated + possibly 1 admin thumb
    initial_job_count = enqueued_jobs.select { |j| j[:job] == Folio::GenerateThumbnailJob }.size

    page.update!(cover: image)

    final_job_count = enqueued_jobs.select { |j| j[:job] == Folio::GenerateThumbnailJob }.size
    added_jobs = final_job_count - initial_job_count
    assert added_jobs >= 2, "Expected at least 2 GenerateThumbnailJob, got #{added_jobs}"

    perform_enqueued_jobs only: Folio::GenerateThumbnailJob

    page.reload
    image.reload

    hash = page.cover_placement.check_pregenerated_thumbnails
    assert_equal [], hash[:loading]
    assert_equal [], hash[:missing]

    broken_thumbnail_sizes = image.thumbnail_sizes.without(THUMB_SIZE_TWO).merge({
      THUMB_SIZE => image.thumbnail_sizes[THUMB_SIZE].merge(url: "https://doader.s3.amazonaws.com/250x250.gif"),
    })
    image.update_column(:thumbnail_sizes, broken_thumbnail_sizes)

    page.reload
    image.reload

    hash = page.cover_placement.check_pregenerated_thumbnails
    assert_equal [THUMB_SIZE_TWO], hash[:missing]
    assert_equal [THUMB_SIZE], hash[:loading]

    assert_enqueued_jobs 0, only: Folio::GenerateThumbnailJob

    page.cover_placement.check_pregenerated_thumbnails!

    page.reload
    image.reload

    assert image.thumbnail_sizes[THUMB_SIZE][:url].include?("doader.")
    assert image.thumbnail_sizes[THUMB_SIZE_TWO][:url].include?("doader.")

    assert_enqueued_jobs 2, only: Folio::GenerateThumbnailJob
  end
end

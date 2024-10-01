# frozen_string_literal: true

require "test_helper"

class Folio::GenerateThumbnailJobTest < ActiveJob::TestCase
  test "thumb" do
    image = create(:folio_file_image, additional_data: { "generate_thumbnails_in_test" => true })

    assert_nil image.thumbnail_sizes["100x100#"]

    perform_enqueued_jobs do
      image.thumb("100x100#")
    end

    image.reload

    assert_match(/test\.jpg\Z/, image.thumbnail_sizes["100x100#"][:url])
    assert_match(/test\.webp\Z/, image.thumbnail_sizes["100x100#"][:webp_url])
  end
end

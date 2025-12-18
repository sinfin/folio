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

  test "uses fallback image when file is missing" do
    skip "Test only runs with local file datastore to avoid S3 access" unless Dragonfly.app.datastore.is_a?(Dragonfly::FileDataStore)

    image = create(:folio_file_image, additional_data: { "generate_thumbnails_in_test" => true })
    file_uid = image.file_uid

    # Delete the file from local datastore to simulate missing file
    Dragonfly.app.datastore.destroy(file_uid) if file_uid

    perform_enqueued_jobs do
      result = image.thumb("100x100#")
      assert_not_nil result
      assert_not_nil result.url
    end

    image.reload

    # Verify thumbnail was generated successfully despite missing file
    assert_not_nil image.thumbnail_sizes["100x100#"]
    assert_not_nil image.thumbnail_sizes["100x100#"][:uid]
    assert_not_nil image.thumbnail_sizes["100x100#"][:url]
  end
end

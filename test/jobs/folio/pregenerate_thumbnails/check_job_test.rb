# frozen_string_literal: true

require "test_helper"

class Folio::PregenerateThumbnails::CheckJobTest < ActiveJob::TestCase
  test "perform" do
    page = create(:folio_page)

    perform_enqueued_jobs do
      page.cover = create(:folio_file_image, additional_data: { "generate_thumbnails_in_test" => true })
      page.cover.update!(thumbnail_sizes: {})
    end

    assert_equal 0, enqueued_jobs.size
    assert_nil page.cover.thumbnail_sizes[Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE]

    perform_enqueued_jobs do
      Folio::PregenerateThumbnails::CheckJob.perform_now(page)
    end

    assert page.cover.reload.thumbnail_sizes[Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE]
  end
end

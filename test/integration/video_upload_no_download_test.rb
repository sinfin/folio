# frozen_string_literal: true

require "test_helper"

class VideoUploadNoDownloadTest < ActiveSupport::TestCase
  test "video file metadata is extracted without full file download" do
    video = create(:folio_file_video)

    # Verify metadata was extracted
    assert_not_nil video.file_track_duration, "Duration should be extracted"
    assert_not_nil video.file_width, "Width should be extracted"
    assert_not_nil video.file_height, "Height should be extracted"

    # Verify file_url_or_path returns correct type
    result = video.file_url_or_path
    assert result.is_a?(String)

    # In test env (FileDataStore), should be local path
    if Dragonfly.app.datastore.is_a?(Dragonfly::FileDataStore)
      assert_not result.start_with?("http")
    end
  end
end

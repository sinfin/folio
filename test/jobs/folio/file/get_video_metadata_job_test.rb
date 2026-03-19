# frozen_string_literal: true

require "test_helper"

class Folio::File::GetVideoMetadataJobTest < ActiveJob::TestCase
  test "extracts duration, width, height from local video file" do
    file_path = Folio::Engine.root.join("test/fixtures/folio/blank.mp4").to_s
    result = Folio::File::GetVideoMetadataJob.perform_now(file_path)

    assert result.is_a?(Hash)
    assert result[:duration].is_a?(Integer)
    assert result[:duration] > 0
    assert result[:width].is_a?(Integer)
    assert result[:width] > 0
    assert result[:height].is_a?(Integer)
    assert result[:height] > 0
  end

  test "returns nil values gracefully for invalid path" do
    result = Folio::File::GetVideoMetadataJob.perform_now("/nonexistent/file.mp4")

    assert result.is_a?(Hash)
    assert_nil result[:duration]
    assert_nil result[:width]
    assert_nil result[:height]
  end
end

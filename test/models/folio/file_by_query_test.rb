# frozen_string_literal: true

require "test_helper"

class Folio::FileByQueryTest < ActiveSupport::TestCase
  # Filenames coming from external tools often look like hostnames
  # (e.g. "ssstwitter.com_1781448018455.mp4"). PostgreSQL full-text search
  # stores "ssstwitter.com" as a single `host` lexeme, while pg_search splits
  # the query on dots and ANDs the terms, so "com" never matches and the whole
  # filename search returns nothing. by_query must still find such files.
  def video_with_file_name(file_name)
    video = create(:folio_file_video)
    video.update!(file_name:)
    video.reload
  end

  test "by_query finds a file by its full dotted filename" do
    video = video_with_file_name("ssstwitter.com_1781448018455.mp4")

    assert_includes Folio::File::Video.by_query("ssstwitter.com_1781448018455.mp4").pluck(:id),
                    video.id
  end

  test "by_query finds a file by a mid-filename token" do
    video = video_with_file_name("ssstwitter.com_1781448018455.mp4")

    assert_includes Folio::File::Video.by_query("1781448018455").pluck(:id),
                    video.id
  end

  test "by_query still finds a file by a leading filename token" do
    video = video_with_file_name("ssstwitter.com_1781448018455.mp4")

    assert_includes Folio::File::Video.by_query("ssstwitter").pluck(:id),
                    video.id
  end

  test "by_query does not match unrelated files" do
    video_with_file_name("ssstwitter.com_1781448018455.mp4")
    other = video_with_file_name("completely-different-name.mp4")

    assert_not_includes Folio::File::Video.by_query("ssstwitter.com_1781448018455.mp4").pluck(:id),
                        other.id
  end
end

# frozen_string_literal: true

require "test_helper"

class Folio::OpenAi::TranscribeSubtitlesJobTest < ActiveJob::TestCase
  test "calls api and updates subtitles" do
    video_file = Folio::File::Video.new(site: get_any_site)
    video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")

    job = Folio::OpenAi::TranscribeSubtitlesJob.new(video_file, "cs")
    def job.extract_and_compress_audio(_video_file_path, _audio_file_path)
      true
    end
    def job.whisper_api_request(_audio_tempfile, _lang)
      "WEBVTT\n\n00:00:00.000 --> 00:00:03.000\nTest"
    end
    job.perform_now

    assert_equal video_file.subtitles_cs, "00:00:00.000 --> 00:00:03.000\nTest"
  end
end

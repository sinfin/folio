# frozen_string_literal: true

require "test_helper"

class Folio::ElevenLabs::TranscribeSubtitlesJobTest < ActiveJob::TestCase
  test "calls api and updates subtitles" do
    video_file = Folio::File::Video.new(site: get_any_site)
    video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video_file.save

    assert_nil video_file.subtitles_cs_text

    job = Folio::ElevenLabs::TranscribeSubtitlesJob.new(video_file, lang: "cs")
    def job.elevenlabs_speech_to_text_request(_video_url)
      {
        "text" => "Test",
        "words" => [
          {
            "text" => "Test",
            "start" => 0.0,
            "end" => 3.0,
            "type" => "word",
            "speaker_id" => "speaker_0"
          }
        ]
      }
    end
    job.perform_now

    assert_equal "00:00:00.000 --> 00:00:03.000\nTest", video_file.subtitles_cs_text
  end
end 
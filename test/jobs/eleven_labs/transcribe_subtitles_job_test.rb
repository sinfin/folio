# frozen_string_literal: true

require "test_helper"

class Folio::ElevenLabs::TranscribeSubtitlesJobTest < ActiveJob::TestCase
  test "calls api with additional_formats and updates subtitles using SRT conversion" do
    video_file = Folio::File::Video.new(site: get_any_site)
    video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video_file.save

    assert_nil video_file.subtitles_cs_text

    job = Folio::ElevenLabs::TranscribeSubtitlesJob.new(video_file, lang: "cs")
    def job.elevenlabs_speech_to_text_request(_video_url)
      {
        "language_code" => "cs",
        "language_probability" => 0.99,
        "text" => "Dobrý den, jak se máte?",
        "words" => [
          {
            "word" => "Dobrý",
            "start" => 0.0,
            "end" => 0.5
          },
          {
            "word" => "den,",
            "start" => 0.5,
            "end" => 1.0
          },
          {
            "word" => "jak",
            "start" => 1.5,
            "end" => 1.8
          },
          {
            "word" => "se",
            "start" => 1.8,
            "end" => 2.0
          },
          {
            "word" => "máte?",
            "start" => 2.0,
            "end" => 3.0
          }
        ],
        "additional_formats" => [
          {
            "format" => "srt",
            "content" => "1\n00:00:00,000 --> 00:00:01,000\nDobrý den,\n\n2\n00:00:01,500 --> 00:00:03,000\njak se máte?\n\n"
          }
        ]
      }
    end
    job.perform_now

    expected_vtt = "WEBVTT\n\n1\n00:00:00.000 --> 00:00:01.000\nDobrý den,\n\n2\n00:00:01.500 --> 00:00:03.000\njak se máte?"
    assert_equal expected_vtt, video_file.subtitles_cs_text
    assert_equal "ready", video_file.get_subtitles_state_for("cs")
  end

  test "falls back to word-by-word processing when additional_formats is not available" do
    video_file = Folio::File::Video.new(site: get_any_site)
    video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video_file.save

    job = Folio::ElevenLabs::TranscribeSubtitlesJob.new(video_file, lang: "cs")
    def job.elevenlabs_speech_to_text_request(_video_url)
      {
        "language_code" => "cs",
        "text" => "Test",
        "words" => [
          {
            "word" => "Test",
            "start" => 0.0,
            "end" => 3.0
          }
        ]
        # No additional_formats in response
      }
    end
    job.perform_now

    expected_vtt = "WEBVTT\n\n00:00:00.000 --> 00:00:03.000\nTest"
    assert_equal expected_vtt, video_file.subtitles_cs_text
    assert_equal "ready", video_file.get_subtitles_state_for("cs")
  end

  test "handles API errors gracefully" do
    video_file = Folio::File::Video.new(site: get_any_site)
    video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video_file.save

    job = Folio::ElevenLabs::TranscribeSubtitlesJob.new(video_file, lang: "cs")
    def job.elevenlabs_speech_to_text_request(_video_url)
      raise "ElevenLabs API error: 400 / Invalid request"
    end

    assert_raises(RuntimeError, "ElevenLabs API error: 400 / Invalid request") do
      job.perform_now
    end

    assert_equal "failed", video_file.get_subtitles_state_for("cs")
  end

  test "validates file size against ElevenLabs limits" do
    video_file = Folio::File::Video.new(site: get_any_site)
    video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video_file.save

    # Mock file size to exceed the limit
    def video_file.file_size
      Folio::ElevenLabs::TranscribeSubtitlesJob::MAX_FILE_SIZE_BYTES + 1
    end

    job = Folio::ElevenLabs::TranscribeSubtitlesJob.new(video_file, lang: "cs")

    assert_raises(RuntimeError, /File size .* exceeds ElevenLabs limit/) do
      job.perform_now
    end

    assert_equal "failed", video_file.get_subtitles_state_for("cs")
  end
end 
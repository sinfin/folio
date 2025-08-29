# frozen_string_literal: true

require "test_helper"

class Folio::ElevenLabs::TranscribeSubtitlesJobTest < ActiveJob::TestCase
  test "calls api with additional_formats and updates subtitles using SRT conversion" do
    video_file = Folio::File::Video.new(site: get_any_site)
    video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video_file.save

    assert_nil video_file.subtitles_cs_text

    job = Folio::ElevenLabs::TranscribeSubtitlesJob.new
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
    job.perform(video_file)

    expected_vtt = "00:00:00.000 --> 00:00:01.000\nDobrý den,\n\n00:00:01.500 --> 00:00:03.000\njak se máte?"
    assert_equal expected_vtt, video_file.subtitles_cs_text
    assert_equal "ready", video_file.get_subtitles_state_for("cs")
  end

  test "handles missing additional_formats gracefully" do
    video_file = Folio::File::Video.new(site: get_any_site)
    video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video_file.save

    job = Folio::ElevenLabs::TranscribeSubtitlesJob.new
    def job.elevenlabs_speech_to_text_request(_video_url)
      {
        "language_code" => "cs",
        "language_probability" => 0.99,
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

    assert_raises(RuntimeError) do
      job.perform(video_file)
    end

    # Should mark transcription as failed
    assert_equal "failed", video_file.subtitles_transcription_status
  end

  test "handles API errors gracefully" do
    video_file = Folio::File::Video.new(site: get_any_site)
    video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video_file.save

    job = Folio::ElevenLabs::TranscribeSubtitlesJob.new
    def job.elevenlabs_speech_to_text_request(_video_url)
      raise "ElevenLabs API error: 400 / Invalid request"
    end

    assert_raises(RuntimeError) do
      job.perform(video_file)
    end

    # Should mark transcription as failed in video metadata
    assert_equal "failed", video_file.subtitles_transcription_status
  end

  test "validates file size against ElevenLabs limits" do
    video_file = Folio::File::Video.new(site: get_any_site)
    video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
    video_file.save

    # Mock file size to exceed the limit
    def video_file.file_size
      Folio::ElevenLabs::TranscribeSubtitlesJob::MAX_FILE_SIZE_BYTES + 1
    end

    job = Folio::ElevenLabs::TranscribeSubtitlesJob.new

    # New implementation returns early instead of raising exception
    job.perform(video_file)

    # Should mark transcription as failed in video metadata
    assert_equal "failed", video_file.subtitles_transcription_status
  end
end

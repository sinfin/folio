# frozen_string_literal: true

require "test_helper"

class Folio::File::Video::HasSubtitlesTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @video_file = Folio::File::Video.new(site: get_any_site)
    @video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
  end

  class TranscribeSubtitlesFile < Folio::File::Video
    def transcribe_subtitles_job_class
      Folio::OpenAi::TranscribeSubtitlesJob
    end
  end

  test "subtitles state changes when subtitles text is set" do
    @video_file.set_subtitles_text_for("cs", "00:00:00.000 --> 00:00:03.000\nTest")
    assert_equal @video_file.get_subtitles_text_for("cs"), "00:00:00.000 --> 00:00:03.000\nTest"
    assert_equal @video_file.get_subtitles_state_for("cs"), "ready"
  end

  test "enqueues transcribe subtitles job if enabled" do
    assert_no_enqueued_jobs only: Folio::OpenAi::TranscribeSubtitlesJob do
      @video_file.save!
    end
    assert_nil @video_file.get_subtitles_state_for("cs")

    @video_file = TranscribeSubtitlesFile.new(site: get_any_site)
    @video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")

    assert_enqueued_jobs 1, only: Folio::OpenAi::TranscribeSubtitlesJob do
      @video_file.save!
    end
    assert_equal @video_file.get_subtitles_state_for("cs"), "processing"
  end

  test "subtitles are validated" do
    subtitles = "00:00:00.000 --> 00:00:03.000\nTest\n"
    @video_file.set_subtitles_text_for("cs", subtitles)
    assert @video_file.valid?

    subtitles += "00:00:05.000 --> 00:00:08.000 align:start\nTest\n"
    @video_file.set_subtitles_text_for("cs", subtitles)
    assert @video_file.valid?

    subtitles += "\n\nNOTE Comment\n"
    @video_file.set_subtitles_text_for("cs", subtitles)
    assert @video_file.valid?

    subtitles += "00:00:10,000 --> 00:00:13,000\nInvalid timecode sequence\n"
    @video_file.set_subtitles_text_for("cs", subtitles)
    assert_not @video_file.valid?
    assert @video_file.errors.added?(:subtitles_cs_text, :invalid_subtitle_block, line: 8)
  end
end

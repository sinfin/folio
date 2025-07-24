# frozen_string_literal: true

require "test_helper"

class Folio::File::Video::HasSubtitlesTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @video_file = Folio::File::Video.new(site: get_any_site)
    @video_file.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")
  end

  test "subtitles state changes when subtitles text is set" do
    @video_file.set_subtitles_text_for("cs", "00:00:00.000 --> 00:00:03.000\nTest")
    assert_equal @video_file.get_subtitles_text_for("cs"), "00:00:00.000 --> 00:00:03.000\nTest"
    assert_equal @video_file.get_subtitles_state_for("cs"), "ready"
  end

  test "enqueues transcribe subtitles job if enabled - OpenAI" do
    # Without job class configured, no jobs should be enqueued
    assert_no_enqueued_jobs only: Folio::OpenAi::TranscribeSubtitlesJob do
      @video_file.save!
    end
    assert_nil @video_file.get_subtitles_state_for("cs")

    # Mock app configuration for OpenAI
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        @video_file_with_config = Folio::File::Video.new(site: get_any_site)
        @video_file_with_config.file = Folio::Engine.root.join("test/fixtures/folio/blank.mp4")

        # With job class configured, jobs should be enqueued
        assert_enqueued_jobs 1, only: Folio::OpenAi::TranscribeSubtitlesJob do
          @video_file_with_config.save!
        end
        assert_equal @video_file_with_config.get_subtitles_state_for("cs"), "processing"
      end
    end
  end

  test "enqueues transcribe subtitles job if enabled - ElevenLabs" do
    # Mock app configuration for ElevenLabs
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::ElevenLabs::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        assert_enqueued_jobs 1, only: Folio::ElevenLabs::TranscribeSubtitlesJob do
          @video_file.save!
        end
        assert_equal @video_file.get_subtitles_state_for("cs"), "processing"
      end
    end
  end

  test "smart transcribe_subtitles! does not override ready subtitles - OpenAI" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        @video_file.save!

        # Set subtitles to ready state
        @video_file.set_subtitles_text_for("cs", "00:00:00.000 --> 00:00:03.000\nTest")
        @video_file.set_subtitles_state_for("cs", "ready")
        @video_file.save!

        assert_equal "ready", @video_file.get_subtitles_state_for("cs")

        # Calling transcribe_subtitles! should not override ready subtitles
        assert_no_enqueued_jobs only: Folio::OpenAi::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!
        end

        assert_equal "ready", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "smart transcribe_subtitles! does not override ready subtitles - ElevenLabs" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::ElevenLabs::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        @video_file.save!

        # Set subtitles to ready state
        @video_file.set_subtitles_text_for("cs", "00:00:00.000 --> 00:00:03.000\nTest")
        @video_file.set_subtitles_state_for("cs", "ready")
        @video_file.save!

        assert_equal "ready", @video_file.get_subtitles_state_for("cs")

        # Calling transcribe_subtitles! should not override ready subtitles
        assert_no_enqueued_jobs only: Folio::ElevenLabs::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!
        end

        assert_equal "ready", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "smart transcribe_subtitles! does not duplicate processing jobs - OpenAI" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        @video_file.save!

        # Set subtitles to processing state
        @video_file.set_subtitles_state_for("cs", "processing")
        @video_file.save!

        assert_equal "processing", @video_file.get_subtitles_state_for("cs")

        # Calling transcribe_subtitles! should not enqueue duplicate jobs
        assert_no_enqueued_jobs only: Folio::OpenAi::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!
        end

        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "smart transcribe_subtitles! does not duplicate processing jobs - ElevenLabs" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::ElevenLabs::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        @video_file.save!

        # Set subtitles to processing state
        @video_file.set_subtitles_state_for("cs", "processing")
        @video_file.save!

        assert_equal "processing", @video_file.get_subtitles_state_for("cs")

        # Calling transcribe_subtitles! should not enqueue duplicate jobs
        assert_no_enqueued_jobs only: Folio::ElevenLabs::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!
        end

        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "transcribe_subtitles! with force parameter overrides ready subtitles - OpenAI" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        @video_file.save!

        # Set subtitles to ready state
        @video_file.set_subtitles_text_for("cs", "00:00:00.000 --> 00:00:03.000\nTest")
        @video_file.set_subtitles_state_for("cs", "ready")
        @video_file.save!

        assert_equal "ready", @video_file.get_subtitles_state_for("cs")

        # Force should override ready state
        assert_enqueued_jobs 1, only: Folio::OpenAi::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!(force: true)
        end

        @video_file.reload
        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "transcribe_subtitles! with force parameter overrides ready subtitles - ElevenLabs" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::ElevenLabs::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        @video_file.save!

        # Set subtitles to ready state
        @video_file.set_subtitles_text_for("cs", "00:00:00.000 --> 00:00:03.000\nTest")
        @video_file.set_subtitles_state_for("cs", "ready")
        @video_file.save!

        assert_equal "ready", @video_file.get_subtitles_state_for("cs")

        # Force should override ready state
        assert_enqueued_jobs 1, only: Folio::ElevenLabs::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!(force: true)
        end

        @video_file.reload
        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "transcribe_subtitles! with force parameter overrides processing state - OpenAI" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        @video_file.save!

        # Set subtitles to processing state
        @video_file.set_subtitles_state_for("cs", "processing")
        @video_file.save!

        assert_equal "processing", @video_file.get_subtitles_state_for("cs")

        # Force should override processing state and enqueue new job
        assert_enqueued_jobs 1, only: Folio::OpenAi::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!(force: true)
        end

        @video_file.reload
        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "transcribe_subtitles! with force parameter overrides processing state - ElevenLabs" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::ElevenLabs::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        @video_file.save!

        # Set subtitles to processing state
        @video_file.set_subtitles_state_for("cs", "processing")
        @video_file.save!

        assert_equal "processing", @video_file.get_subtitles_state_for("cs")

        # Force should override processing state and enqueue new job
        assert_enqueued_jobs 1, only: Folio::ElevenLabs::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!(force: true)
        end

        @video_file.reload
        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "transcribe_subtitles! processes blank subtitles normally - OpenAI" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        # Before save, subtitles should be nil
        assert_nil @video_file.get_subtitles_state_for("cs")

        # Save triggers automatic subtitle processing
        assert_enqueued_jobs 1, only: Folio::OpenAi::TranscribeSubtitlesJob do
          @video_file.save!
        end

        # After save, subtitles should be processing
        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "transcribe_subtitles! processes blank subtitles normally - ElevenLabs" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::ElevenLabs::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        # Before save, subtitles should be nil
        assert_nil @video_file.get_subtitles_state_for("cs")

        # Save triggers automatic subtitle processing
        assert_enqueued_jobs 1, only: Folio::ElevenLabs::TranscribeSubtitlesJob do
          @video_file.save!
        end

        # After save, subtitles should be processing
        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "transcribe_subtitles! manual call processes blank subtitles - OpenAI" do
    # Create a video file without automatic processing (no job class configured initially)
    @video_file.save!

    # Blank subtitles should be processed normally
    assert_nil @video_file.get_subtitles_state_for("cs")

    # Mock app configuration for OpenAI
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        # Manual call should enqueue job
        assert_enqueued_jobs 1, only: Folio::OpenAi::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!
        end

        # After manual call, subtitles should be processing
        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "transcribe_subtitles! manual call processes blank subtitles - ElevenLabs" do
    # Create a video file without automatic processing (no job class configured initially)
    @video_file.save!

    # Blank subtitles should be processed normally
    assert_nil @video_file.get_subtitles_state_for("cs")

    # Mock app configuration for ElevenLabs
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::ElevenLabs::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        # Manual call should enqueue job
        assert_enqueued_jobs 1, only: Folio::ElevenLabs::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!
        end

        # After manual call, subtitles should be processing
        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "transcribe_subtitles! processes failed subtitles normally - OpenAI" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        @video_file.save!

        # Set subtitles to failed state
        @video_file.set_subtitles_state_for("cs", "failed")
        @video_file.save!

        assert_equal "failed", @video_file.get_subtitles_state_for("cs")

        # Failed subtitles should be processed normally (retry)
        assert_enqueued_jobs 1, only: Folio::OpenAi::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!
        end

        @video_file.reload
        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "transcribe_subtitles! processes failed subtitles normally - ElevenLabs" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::ElevenLabs::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        @video_file.save!

        # Set subtitles to failed state
        @video_file.set_subtitles_state_for("cs", "failed")
        @video_file.save!

        assert_equal "failed", @video_file.get_subtitles_state_for("cs")

        # Failed subtitles should be processed normally (retry)
        assert_enqueued_jobs 1, only: Folio::ElevenLabs::TranscribeSubtitlesJob do
          @video_file.transcribe_subtitles!
        end

        @video_file.reload
        assert_equal "processing", @video_file.get_subtitles_state_for("cs")
      end
    end
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

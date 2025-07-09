# frozen_string_literal: true

require "test_helper"

class Folio::Files::RestartProcessingMediaJobTest < ActiveJob::TestCase
  def setup
    @site = create_and_host_site
  end

  test "restart_stuck_subtitle_processing resets old processing subtitles" do
    # Create a video file with subtitles enabled
    video_file = create(:folio_file_video, site: @site)

    # Stub the job class to enable subtitles
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        # Set subtitle to processing state and update timestamp to over 1 hour ago
        video_file.set_subtitles_state_for("cs", "processing")
        video_file.update_columns(
          additional_data: video_file.additional_data,
          updated_at: 2.hours.ago
        )

        assert_equal "processing", video_file.get_subtitles_state_for("cs")

        # Run the job
        Folio::Files::RestartProcessingMediaJob.perform_now

        # Should reset stuck processing to failed
        video_file.reload
        assert_equal "failed", video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "restart_stuck_subtitle_processing ignores recent processing subtitles" do
    # Create a video file with subtitles enabled
    video_file = create(:folio_file_video, site: @site)

    # Stub the job class to enable subtitles
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        # Set subtitle to processing state with recent timestamp
        video_file.set_subtitles_state_for("cs", "processing")
        video_file.update_columns(
          additional_data: video_file.additional_data,
          updated_at: 30.minutes.ago
        )

        assert_equal "processing", video_file.get_subtitles_state_for("cs")

        # Run the job
        Folio::Files::RestartProcessingMediaJob.perform_now

        # Should NOT reset recent processing
        video_file.reload
        assert_equal "processing", video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "restart_stuck_subtitle_processing ignores ready subtitles" do
    # Create a video file with subtitles enabled
    video_file = create(:folio_file_video, site: @site)

    # Stub the job class to enable subtitles
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        # Set subtitle to ready state
        video_file.set_subtitles_text_for("cs", "00:00:00.000 --> 00:00:03.000\nTest")
        video_file.set_subtitles_state_for("cs", "ready")
        video_file.update_columns(
          additional_data: video_file.additional_data,
          updated_at: 2.hours.ago
        )

        assert_equal "ready", video_file.get_subtitles_state_for("cs")

        # Run the job
        Folio::Files::RestartProcessingMediaJob.perform_now

        # Should NOT touch ready subtitles
        video_file.reload
        assert_equal "ready", video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "restart_stuck_subtitle_processing ignores failed subtitles" do
    # Create a video file with subtitles enabled
    video_file = create(:folio_file_video, site: @site)

    # Stub the job class to enable subtitles
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        # Set subtitle to failed state
        video_file.set_subtitles_state_for("cs", "failed")
        video_file.update_columns(
          additional_data: video_file.additional_data,
          updated_at: 2.hours.ago
        )

        assert_equal "failed", video_file.get_subtitles_state_for("cs")

        # Run the job
        Folio::Files::RestartProcessingMediaJob.perform_now

        # Should NOT touch failed subtitles
        video_file.reload
        assert_equal "failed", video_file.get_subtitles_state_for("cs")
      end
    end
  end

  test "restart_stuck_subtitle_processing skips disabled subtitles" do
    # Create a video file without subtitles enabled
    video_file = create(:folio_file_video, site: @site)

    # No job class stubbed = subtitles disabled

    # Set subtitle to processing state manually
    video_file.set_subtitles_state_for("cs", "processing")
    video_file.update_columns(
      additional_data: video_file.additional_data,
      updated_at: 2.hours.ago
    )

    assert_equal "processing", video_file.get_subtitles_state_for("cs")

    # Run the job
    Folio::Files::RestartProcessingMediaJob.perform_now

    # Should NOT reset processing when subtitles are disabled
    video_file.reload
    assert_equal "processing", video_file.get_subtitles_state_for("cs")
  end

  test "restart_stuck_subtitle_processing handles multiple languages" do
    # Create two video files with different subtitle states
    video_file_1 = create(:folio_file_video, site: @site)
    video_file_2 = create(:folio_file_video, site: @site)

    # Stub the job class to enable subtitles
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        # Set first video to stuck processing state
        video_file_1.set_subtitles_state_for("cs", "processing")
        video_file_1.update_columns(
          additional_data: video_file_1.additional_data,
          updated_at: 2.hours.ago
        )

        # Set second video to ready state
        video_file_2.set_subtitles_text_for("cs", "00:00:00.000 --> 00:00:03.000\nTest")
        video_file_2.set_subtitles_state_for("cs", "ready")
        video_file_2.update_columns(
          additional_data: video_file_2.additional_data,
          updated_at: 2.hours.ago
        )

        assert_equal "processing", video_file_1.get_subtitles_state_for("cs")
        assert_equal "ready", video_file_2.get_subtitles_state_for("cs")

        # Run the job
        Folio::Files::RestartProcessingMediaJob.perform_now

        # Should reset only stuck processing, leave ready alone
        video_file_1.reload
        video_file_2.reload
        assert_equal "failed", video_file_1.get_subtitles_state_for("cs")
        assert_equal "ready", video_file_2.get_subtitles_state_for("cs")
      end
    end
  end

  test "restart_stuck_subtitle_processing only processes ready video files" do
    # Create a video file and manually set it to processing state
    video_file = create(:folio_file_video, site: @site)

    # Manually set the video to processing state without triggering callbacks
    video_file.update_columns(aasm_state: "processing")

    # Stub the job class to enable subtitles
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      Folio::File::Video.stub(:enabled_subtitle_languages, ["cs"]) do
        # Set subtitle to processing state
        video_file.set_subtitles_state_for("cs", "processing")
        video_file.update_columns(
          additional_data: video_file.additional_data,
          updated_at: 2.hours.ago
        )

        assert_equal "processing", video_file.get_subtitles_state_for("cs")
        assert_equal "processing", video_file.aasm_state

        # Run the job
        Folio::Files::RestartProcessingMediaJob.perform_now

        # Should NOT reset subtitles when video file itself is still processing
        video_file.reload
        assert_equal "processing", video_file.get_subtitles_state_for("cs")
      end
    end
  end
end

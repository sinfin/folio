# frozen_string_literal: true

require "test_helper"

class Folio::VideoSubtitleTest < ActiveSupport::TestCase
  def setup
    @site = create_and_host_site
    @video = create(:folio_file_video, site: @site)
    @subtitle = Folio::VideoSubtitle.new(video: @video, language: "cs", format: "vtt")
  end

  test "validates presence of language" do
    @subtitle.language = nil
    assert_not @subtitle.valid?
    assert_includes @subtitle.errors[:language], "je povinná položka"
  end

  test "validates uniqueness of language per video" do
    @subtitle.save!
    duplicate = Folio::VideoSubtitle.new(video: @video, language: "cs", format: "vtt")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:language], "již databáze obsahuje"
  end

  test "validates format inclusion" do
    @subtitle.format = "invalid"
    assert_not @subtitle.valid?
    assert_includes @subtitle.errors[:format], "není v seznamu povolených hodnot"
  end

  test "validates subtitle format when validate_content is true" do
    @subtitle.text = "Invalid VTT content"
    @subtitle.validate_content = true
    assert_not @subtitle.valid?
    assert_includes @subtitle.errors[:text], "má nevalidní text na řádku 1"
  end

  test "does not validate subtitle format by default" do
    @subtitle.text = "Invalid VTT content"
    assert @subtitle.valid?
  end

  test "validates VTT format correctly" do
    valid_vtt = "00:00:01.000 --> 00:00:02.000\nHello world"
    @subtitle.text = valid_vtt
    @subtitle.validate_content = true
    assert @subtitle.valid?
  end

  test "start_transcription! updates metadata correctly" do
    job_class = Folio::ElevenLabs::TranscribeSubtitlesJob
    freeze_time do
      @subtitle.start_transcription!(job_class)

      assert_equal "processing", @subtitle.transcription_state
      assert_equal job_class.to_s, @subtitle.transcription["job_class"]
      assert_equal Time.current.iso8601, @subtitle.transcription["processing_started_at"]
      assert_equal 1, @subtitle.transcription["attempts"]
    end
  end

  test "mark_transcription_ready! with valid content enables subtitle" do
    valid_vtt = "00:00:01.000 --> 00:00:02.000\nHello world"
    freeze_time do
      @subtitle.mark_transcription_ready!(valid_vtt)

      assert @subtitle.enabled?
      assert_equal valid_vtt, @subtitle.text
      assert_equal "ready", @subtitle.transcription_state
      assert_equal Time.current.iso8601, @subtitle.transcription["completed_at"]
      assert @subtitle.validation["is_valid"]
    end
  end

  test "mark_transcription_ready! with invalid content keeps subtitle disabled" do
    invalid_vtt = "Invalid content"
    freeze_time do
      @subtitle.mark_transcription_ready!(invalid_vtt)

      assert_not @subtitle.enabled?
      assert_equal invalid_vtt, @subtitle.text
      assert_equal "ready", @subtitle.transcription_state
      assert_equal Time.current.iso8601, @subtitle.transcription["completed_at"]
      assert_not @subtitle.validation["is_valid"]
      assert @subtitle.validation["validation_errors"].any?
    end
  end

  test "mark_transcription_failed! updates metadata correctly" do
    error_message = "API timeout"
    freeze_time do
      @subtitle.mark_transcription_failed!(error_message)

      assert_equal "failed", @subtitle.transcription_state
      assert_equal error_message, @subtitle.transcription["error_message"]
      assert_equal Time.current.iso8601, @subtitle.transcription["completed_at"]
    end
  end

  test "mark_manual_edit! updates last_edited_at" do
    @subtitle.update_transcription_metadata("job_class" => "SomeJob", "state" => "ready")
    @subtitle.save!

    freeze_time do
      @subtitle.mark_manual_edit!

      # State should remain unchanged - just track the edit
      assert_equal "ready", @subtitle.transcription_state
      assert_equal Time.current.iso8601, @subtitle.manual_edits["last_edited_at"]
    end
  end

  test "auto_generated? returns correct value" do
    assert_not @subtitle.auto_generated?

    @subtitle.update_transcription_metadata("job_class" => "SomeJob")
    assert @subtitle.auto_generated?
  end

  test "processing? returns correct value" do
    assert_not @subtitle.processing?

    @subtitle.update_transcription_metadata("state" => "processing")
    assert @subtitle.processing?
  end

  test "transcription_state returns correct state" do
    assert_equal "pending", @subtitle.transcription_state

    @subtitle.update_transcription_metadata("state" => "ready")
    assert_equal "ready", @subtitle.transcription_state
  end

  test "status_for_display returns correct status" do
    assert_equal "empty", @subtitle.status_for_display

    @subtitle.update_transcription_metadata("state" => "processing")
    assert_equal "processing", @subtitle.status_for_display

    # Clear processing state to test enabled/disabled states
    @subtitle.update_transcription_metadata("state" => "ready")
    @subtitle.text = "Some content"
    @subtitle.enabled = true
    assert_equal "enabled", @subtitle.status_for_display

    @subtitle.enabled = false
    assert_equal "disabled", @subtitle.status_for_display
  end

  test "scopes work correctly" do
    subtitle1 = Folio::VideoSubtitle.create!(video: @video, language: "cs", enabled: true)
    Folio::VideoSubtitle.create!(video: @video, language: "en", enabled: false)
    subtitle3 = Folio::VideoSubtitle.create!(video: @video, language: "de", enabled: true)

    subtitle1.update_transcription_metadata("job_class" => "SomeJob")
    subtitle1.save!

    assert_equal 2, Folio::VideoSubtitle.enabled.count
    assert_includes Folio::VideoSubtitle.enabled, subtitle1
    assert_includes Folio::VideoSubtitle.enabled, subtitle3

    assert_equal 1, Folio::VideoSubtitle.auto_generated.count
    assert_includes Folio::VideoSubtitle.auto_generated, subtitle1

    assert_equal 2, Folio::VideoSubtitle.manually_created.count
  end

  test "last_activity_at returns most recent activity" do
    freeze_time do
      @subtitle.save!
      Time.current

      travel 1.hour
      @subtitle.update_transcription_metadata("completed_at" => Time.current.iso8601)
      @subtitle.save!

      travel 1.hour
      @subtitle.update_manual_edits_metadata
      @subtitle.save!
      manual_time = Time.current

      assert_equal manual_time, @subtitle.last_activity_at
    end
  end

  test "display_name uses I18n translation" do
    I18n.with_locale(:en) do
      assert_equal "Subtitles (czech)", @subtitle.display_name
    end
  end

  test "site returns video's site" do
    assert_equal @video.site, @subtitle.site
  end

  test "time parsing methods handle invalid dates gracefully" do
    @subtitle.update_transcription_metadata("processing_started_at" => "invalid-date")
    assert_nil @subtitle.processing_started_at

    @subtitle.update_transcription_metadata("completed_at" => "invalid-date")
    assert_nil @subtitle.completed_at
  end
end

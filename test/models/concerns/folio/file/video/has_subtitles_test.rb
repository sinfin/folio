# frozen_string_literal: true

require "test_helper"

class Folio::File::Video::HasSubtitlesTest < ActiveSupport::TestCase
  def setup
    @site = create_and_host_site
    @site.update(subtitle_languages: ['cs', 'en'])
    @video = create(:folio_file_video, site: @site)
  end

  test "has_many video_subtitles relationship" do
    assert_respond_to @video, :video_subtitles
    assert_respond_to @video, :subtitles # alias
  end

  test "subtitle_for returns existing subtitle for language" do
    subtitle = @video.video_subtitles.create!(language: 'cs')
    assert_equal subtitle, @video.subtitle_for('cs')
  end

  test "subtitle_for returns nil for non-existing language" do
    assert_nil @video.subtitle_for('cs')
  end

  test "subtitle_for! creates subtitle if it doesn't exist" do
    assert_nil @video.subtitle_for('cs')
    
    subtitle = @video.subtitle_for!('cs')
    assert_not_nil subtitle
    assert_equal 'cs', subtitle.language
    assert subtitle.persisted?
  end

  test "subtitle_for! returns existing subtitle if it exists" do
    existing = @video.video_subtitles.create!(language: 'cs')
    found = @video.subtitle_for!('cs')
    assert_equal existing, found
  end

  test "enabled_subtitle_languages uses site settings when available" do
    assert_equal ['cs', 'en'], @video.class.enabled_subtitle_languages
  end

  test "enabled_subtitle_languages falls back to global config" do
    @site.update(subtitle_languages: [])
    Folio::Current.site = @site
    
    assert_equal Rails.application.config.folio_files_video_enabled_subtitle_languages, 
                 @video.class.enabled_subtitle_languages
  end

  test "set_subtitles_text_for creates and updates subtitle" do
    @video.set_subtitles_text_for('cs', 'Test subtitle')
    
    subtitle = @video.subtitle_for('cs')
    assert_equal 'Test subtitle', subtitle.text
    refute subtitle.auto_generated?
  end

  test "set_subtitles_text_for marks manual override for auto-generated subtitles" do
    subtitle = @video.video_subtitles.create!(language: 'cs')
    subtitle.update_transcription_metadata('job_class' => 'SomeJob', 'state' => 'ready')
    
    @video.set_subtitles_text_for('cs', 'Modified text')
    
    subtitle.reload
    assert_equal 'manual_override', subtitle.transcription_state
    assert subtitle.manual_edits.present?
  end

  test "get_subtitles_text_for returns subtitle text" do
    @video.video_subtitles.create!(language: 'cs', text: 'Test text')
    assert_equal 'Test text', @video.get_subtitles_text_for('cs')
  end

  test "get_subtitles_text_for returns nil for non-existing subtitle" do
    assert_nil @video.get_subtitles_text_for('cs')
  end

  test "get_subtitles_state_for returns correct state for auto-generated subtitles" do
    subtitle = @video.video_subtitles.create!(language: 'cs')
    subtitle.update_transcription_metadata('job_class' => 'SomeJob', 'state' => 'processing')
    
    assert_equal 'processing', @video.get_subtitles_state_for('cs')
  end

  test "get_subtitles_state_for returns state based on enabled for manual subtitles" do
    @video.video_subtitles.create!(language: 'cs', enabled: true)
    assert_equal 'ready', @video.get_subtitles_state_for('cs')
    
    @video.video_subtitles.create!(language: 'en', enabled: false)
    assert_equal 'pending', @video.get_subtitles_state_for('en')
  end

  test "get_subtitles_state_for returns pending for non-existing subtitle" do
    assert_equal 'pending', @video.get_subtitles_state_for('cs')
  end

  test "get_subtitles_processing_started_at_for returns time for auto-generated subtitles" do
    freeze_time do
      subtitle = @video.video_subtitles.create!(language: 'cs')
      subtitle.update_transcription_metadata(
        'job_class' => 'SomeJob',
        'processing_started_at' => Time.current.iso8601
      )
      
      assert_equal Time.current, @video.get_subtitles_processing_started_at_for('cs')
    end
  end

  test "get_subtitles_processing_started_at_for returns nil for manual subtitles" do
    @video.video_subtitles.create!(language: 'cs')
    assert_nil @video.get_subtitles_processing_started_at_for('cs')
  end

  test "transcribe_subtitles! creates subtitles for enabled languages" do
    # Mock the job class
    @video.class.define_singleton_method(:transcribe_subtitles_job_class) do
      Folio::ElevenLabs::TranscribeSubtitlesJob
    end
    
    @video.transcribe_subtitles!
    
    assert_equal 2, @video.video_subtitles.count
    assert @video.subtitle_for('cs').present?
    assert @video.subtitle_for('en').present?
    
    # Check that subtitles are in processing state
    assert_equal 'processing', @video.subtitle_for('cs').transcription_state
    assert_equal 'processing', @video.subtitle_for('en').transcription_state
  end

  test "transcribe_subtitles! skips already processing subtitles unless forced" do
    subtitle = @video.video_subtitles.create!(language: 'cs')
    subtitle.update_transcription_metadata('state' => 'processing')
    
    @video.class.define_singleton_method(:transcribe_subtitles_job_class) do
      Folio::ElevenLabs::TranscribeSubtitlesJob
    end
    
    # Should skip processing subtitle
    @video.transcribe_subtitles!
    subtitle.reload
    assert_equal 'processing', subtitle.transcription_state
    
    # Should reprocess when forced
    @video.transcribe_subtitles!(force: true)
    subtitle.reload
    assert_equal 'processing', subtitle.transcription_state
    assert_equal 2, subtitle.attempts_count # Should increment attempts
  end

  test "transcribe_subtitles! does nothing when job class is not present" do
    @video.class.define_singleton_method(:transcribe_subtitles_job_class) { nil }
    
    @video.transcribe_subtitles!
    assert_equal 0, @video.video_subtitles.count
  end

  test "dynamic language methods are created" do
    # These methods should be available for enabled languages
    assert_respond_to @video, :subtitles_cs
    assert_respond_to @video, :subtitles_cs_text
    assert_respond_to @video, :subtitles_cs_text=
    assert_respond_to @video, :subtitles_cs_enabled?
    assert_respond_to @video, :subtitles_cs_state
    assert_respond_to @video, :subtitles_cs_processing_started_at
    
    assert_respond_to @video, :subtitles_en
    assert_respond_to @video, :subtitles_en_text
    assert_respond_to @video, :subtitles_en_text=
    assert_respond_to @video, :subtitles_en_enabled?
    assert_respond_to @video, :subtitles_en_state
    assert_respond_to @video, :subtitles_en_processing_started_at
  end

  test "dynamic language methods work correctly" do
    subtitle = @video.video_subtitles.create!(language: 'cs', text: 'Test', enabled: true)
    
    assert_equal subtitle, @video.subtitles_cs
    assert_equal 'Test', @video.subtitles_cs_text
    assert @video.subtitles_cs_enabled?
    assert_equal 'ready', @video.subtitles_cs_state
    
    # Test setter
    @video.subtitles_cs_text = 'New text'
    subtitle.reload
    assert_equal 'New text', subtitle.text
  end

  test "subtitles_enabled? returns true when job class is present" do
    @video.class.define_singleton_method(:transcribe_subtitles_job_class) do
      Folio::ElevenLabs::TranscribeSubtitlesJob
    end
    
    assert @video.class.subtitles_enabled?
  end

  test "subtitles_enabled? returns false when job class is not present" do
    @video.class.define_singleton_method(:transcribe_subtitles_job_class) { nil }
    
    refute @video.class.subtitles_enabled?
  end

  test "after_process triggers transcribe_subtitles!" do
    @video.class.define_singleton_method(:transcribe_subtitles_job_class) do
      Folio::ElevenLabs::TranscribeSubtitlesJob
    end
    
    # Mock after_process call
    @video.send(:after_process)
    
    assert_equal 2, @video.video_subtitles.count
  end

  private

  def create_mock_job_class
    Class.new do
      def self.perform_later(video)
        # Mock implementation
      end
      
      def self.to_s
        "MockTranscribeJob"
      end
    end
  end
end 
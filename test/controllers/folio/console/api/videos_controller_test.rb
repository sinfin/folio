# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::VideosControllerTest < Folio::Console::BaseControllerTest
  setup do
    @site = create_and_host_site
    @video = create(:folio_file_video, site: @site)
  end

  test "subtitles_html" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      get url_for([:subtitles_html, :console, :api, @video, format: :json])
      assert_response(:ok)
      assert_match("f-c-files-subtitles-form", response.body)
    end
  end

  test "retranscribe_subtitles" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      post url_for([:retranscribe_subtitles, :console, :api, @video, format: :json])
      assert_response(:ok)
      assert_match("f-c-files-subtitles-form", response.body)
    end
  end

  test "retranscribe_subtitle" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      post url_for([:retranscribe_subtitle, :console, :api, @video, language: 'cs', format: :json])
      assert_response(:ok)
      assert_match("f-c-files-subtitles-form", response.body)
      
      # Check that subtitle was created and set to processing
      subtitle = @video.subtitle_for('cs')
      assert_not_nil subtitle
      assert_equal 'processing', subtitle.transcription_state
    end
  end

  test "retranscribe_subtitle skips if already processing" do
    subtitle = @video.video_subtitles.create!(language: 'cs')
    subtitle.update_transcription_metadata('state' => 'processing')
    
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      post url_for([:retranscribe_subtitle, :console, :api, @video, language: 'cs', format: :json])
      assert_response(:ok)
      
      # Should still be processing, attempts shouldn't increment
      subtitle.reload
      assert_equal 'processing', subtitle.transcription_state
    end
  end

  test "create_subtitle" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      post url_for([:create_subtitle, :console, :api, @video, language: 'cs', format: :json]), params: {
        subtitle: {
          text: "00:00:01.000 --> 00:00:02.000\nHello world",
          enabled: true
        }
      }
      assert_response(:ok)
      assert_match("f-c-files-subtitles-form", response.body)
      
      # Check that subtitle was created
      subtitle = @video.subtitle_for('cs')
      assert_not_nil subtitle
      assert_equal "00:00:01.000 --> 00:00:02.000\nHello world", subtitle.text
      assert subtitle.enabled?
      refute subtitle.auto_generated?
    end
  end

  test "update_subtitle" do
    subtitle = @video.video_subtitles.create!(language: 'cs', text: 'Original text')
    
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      patch url_for([:update_subtitle, :console, :api, @video, language: 'cs', format: :json]), params: {
        subtitle: {
          text: "00:00:01.000 --> 00:00:02.000\nUpdated text",
          enabled: true
        }
      }
      assert_response(:ok)
      assert_match("f-c-files-subtitles-form", response.body)
      
      # Check that subtitle was updated
      subtitle.reload
      assert_equal "00:00:01.000 --> 00:00:02.000\nUpdated text", subtitle.text
      assert subtitle.enabled?
    end
  end

  test "update_subtitle marks manual override for auto-generated subtitles" do
    subtitle = @video.video_subtitles.create!(language: 'cs', text: 'Auto generated')
    subtitle.update_transcription_metadata('job_class' => 'SomeJob', 'state' => 'ready')
    
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      patch url_for([:update_subtitle, :console, :api, @video, language: 'cs', format: :json]), params: {
        subtitle: {
          text: "00:00:01.000 --> 00:00:02.000\nManually edited",
          enabled: true
        }
      }
      assert_response(:ok)
      
      # Check that manual override was marked
      subtitle.reload
      assert_equal 'manual_override', subtitle.transcription_state
      assert subtitle.manual_edits.present?
    end
  end

  test "update_subtitles (legacy compatibility)" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      patch url_for([:update_subtitles, :console, :api, @video, format: :json]), params: {
        file: {
          subtitles_cs_text: "00:00:01.000 --> 00:00:02.000\nCzech subtitle",
          subtitles_cs_enabled: "1",
          subtitles_en_text: "00:00:01.000 --> 00:00:02.000\nEnglish subtitle",
          subtitles_en_enabled: "0"
        }
      }
      assert_response(:ok)
      assert_match("f-c-files-subtitles-form", response.body)
      
      # Check that subtitles were created
      cs_subtitle = @video.subtitle_for('cs')
      en_subtitle = @video.subtitle_for('en')
      
      assert_not_nil cs_subtitle
      assert_equal "00:00:01.000 --> 00:00:02.000\nCzech subtitle", cs_subtitle.text
      assert cs_subtitle.enabled?
      
      assert_not_nil en_subtitle
      assert_equal "00:00:01.000 --> 00:00:02.000\nEnglish subtitle", en_subtitle.text
      refute en_subtitle.enabled?
    end
  end
end

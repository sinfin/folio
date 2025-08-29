# frozen_string_literal: true

require "test_helper"

class Folio::Console::Api::VideosControllerTest < Folio::Console::BaseControllerTest
  setup do
    @site = create_and_host_site
    @site.subtitle_languages = ["cs", "en"]
    @site.save!
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

  test "create_subtitle" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      post "/console/api/file/videos/#{@video.id}/subtitles/cs", params: {
        subtitle: {
          text: "00:00:01.000 --> 00:00:02.000\nTest subtitle",
          enabled: true
        },
        format: :json
      }
      assert_response(:ok)
      assert_match("f-c-files-subtitles-form", response.body)

      # Check that subtitle was created
      subtitle = @video.subtitle_for("cs")
      assert_not_nil subtitle
      assert_equal "00:00:01.000 --> 00:00:02.000\nTest subtitle", subtitle.text
      assert subtitle.enabled?
    end
  end

  test "create_subtitle broadcasts subtitle update" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      # Mock MessageBus to capture published messages
      published_messages = []
      MessageBus.stub(:publish, ->(channel, message, opts = {}) {
        published_messages << { channel: channel, message: message, opts: opts }
      }) do
        post "/console/api/file/videos/#{@video.id}/subtitles/cs", params: {
          subtitle: {
            text: "00:00:01.000 --> 00:00:02.000\nTest subtitle",
            enabled: true
          },
          format: :json
        }
      end

      assert_response(:ok)

      # Check that subtitle update broadcast was sent
      subtitle_update_message = published_messages.find do |msg|
        parsed = JSON.parse(msg[:message])
        parsed["type"] == "Folio::Console::Api::File::VideosController/subtitle_updated"
      rescue JSON::ParserError
        false
      end

      assert_not_nil subtitle_update_message, "Subtitle update broadcast was not sent. Messages: #{published_messages.inspect}"

      parsed_message = JSON.parse(subtitle_update_message[:message])
      assert_equal @video.id, parsed_message["data"]["id"]
    end
  end

  test "update_subtitle" do
    subtitle = @video.video_subtitles.create!(language: "cs", text: "Original text")

    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      patch "/console/api/file/videos/#{@video.id}/subtitles/cs", params: {
        subtitle: {
          text: "00:00:01.000 --> 00:00:02.000\nUpdated text",
          enabled: true
        },
        format: :json
      }
      assert_response(:ok)
      assert_match("f-c-files-subtitles-form", response.body)

      # Check that subtitle was updated
      subtitle.reload
      assert_equal "00:00:01.000 --> 00:00:02.000\nUpdated text", subtitle.text
      assert subtitle.enabled?
    end
  end

  test "update_subtitle broadcasts subtitle update" do
    @video.video_subtitles.create!(language: "cs", text: "Original text")

    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      # Mock MessageBus to capture published messages
      published_messages = []
      MessageBus.stub(:publish, ->(channel, message, opts = {}) {
        published_messages << { channel: channel, message: message, opts: opts }
      }) do
        patch "/console/api/file/videos/#{@video.id}/subtitles/cs", params: {
          subtitle: {
            text: "00:00:01.000 --> 00:00:02.000\nUpdated text",
            enabled: true
          },
          format: :json
        }
      end

      assert_response(:ok)

      # Check that subtitle update broadcast was sent
      subtitle_update_message = published_messages.find do |msg|
        parsed = JSON.parse(msg[:message])
        parsed["type"] == "Folio::Console::Api::File::VideosController/subtitle_updated"
      rescue JSON::ParserError
        false
      end

      assert_not_nil subtitle_update_message, "Subtitle update broadcast was not sent. Messages: #{published_messages.inspect}"

      parsed_message = JSON.parse(subtitle_update_message[:message])
      assert_equal @video.id, parsed_message["data"]["id"]
    end
  end

  test "update_subtitle marks manual override for auto-generated subtitles" do
    subtitle = @video.video_subtitles.create!(language: "cs", text: "Auto generated")
    subtitle.update_transcription_metadata("job_class" => "SomeJob", "state" => "ready")

    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      patch "/console/api/file/videos/#{@video.id}/subtitles/cs", params: {
        subtitle: {
          text: "00:00:01.000 --> 00:00:02.000\nManually edited",
          enabled: true
        },
        format: :json
      }
      assert_response(:ok)

      # Check that manual override was marked
      subtitle.reload
      assert subtitle.manual_edits.present?
    end
  end

  test "delete_subtitle" do
    @video.video_subtitles.create!(language: "cs", text: "Test subtitle")

    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      delete "/console/api/file/videos/#{@video.id}/subtitles/cs", params: { format: :json }
      assert_response(:ok)
      assert_match("f-c-files-subtitles-form", response.body)

      # Check that subtitle was deleted
      assert_nil @video.subtitle_for("cs")
    end
  end

  test "delete_subtitle broadcasts subtitle update" do
    @video.video_subtitles.create!(language: "cs", text: "Test subtitle")

    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      # Mock MessageBus to capture published messages
      published_messages = []
      MessageBus.stub(:publish, ->(channel, message, opts = {}) {
        published_messages << { channel: channel, message: message, opts: opts }
      }) do
        delete "/console/api/file/videos/#{@video.id}/subtitles/cs", params: { format: :json }
      end

      assert_response(:ok)

      # Check that subtitle update broadcast was sent
      subtitle_update_message = published_messages.find do |msg|
        parsed = JSON.parse(msg[:message])
        parsed["type"] == "Folio::Console::Api::File::VideosController/subtitle_updated"
      rescue JSON::ParserError
        false
      end

      assert_not_nil subtitle_update_message, "Subtitle update broadcast was not sent. Messages: #{published_messages.inspect}"

      parsed_message = JSON.parse(subtitle_update_message[:message])
      assert_equal @video.id, parsed_message["data"]["id"]
    end
  end
end

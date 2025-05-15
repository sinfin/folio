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
      assert_match("f-c-files-has-subtitles-form", response.body)
    end
  end

  test "retranscribe_subtitles" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      post url_for([:retranscribe_subtitles, :console, :api, @video, format: :json])
      assert_response(:ok)
      assert_match("f-c-files-has-subtitles-form", response.body)
    end
  end

  test "update_subtitles" do
    Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
      patch url_for([:update_subtitles, :console, :api, @video, format: :json]), params: {
        file: {
          subtitles_cs_text: "foo",
        }
      }
      assert_response(:ok)
      assert_match("f-c-files-has-subtitles-form", response.body)
    end
  end
end

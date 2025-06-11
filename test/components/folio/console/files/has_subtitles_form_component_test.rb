# frozen_string_literal: true

require "test_helper"

class Folio::Console::Files::HasSubtitlesFormComponentTest < Folio::Console::ComponentTest
  def test_render
    with_controller_class(Folio::Console::File::VideosController) do
      with_request_url "/console/file/videos" do
        file = create(:folio_file_video)

        render_inline(Folio::Console::Files::HasSubtitlesFormComponent.new(file:))

        assert_no_selector(".f-c-files-has-subtitles-form")
      end
    end
  end

  def test_render_valid
    with_controller_class(Folio::Console::File::VideosController) do
      with_request_url "/console/file/videos" do
        Folio::File::Video.stub(:transcribe_subtitles_job_class, Folio::OpenAi::TranscribeSubtitlesJob) do
          file = create(:folio_file_video)

          render_inline(Folio::Console::Files::HasSubtitlesFormComponent.new(file:))

          assert_selector(".f-c-files-has-subtitles-form")
        end
      end
    end
  end
end

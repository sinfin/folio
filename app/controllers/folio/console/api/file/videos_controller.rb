# frozen_string_literal: true

class Folio::Console::Api::File::VideosController < Folio::Console::Api::BaseController
  include Folio::Console::Api::FileControllerBase

  folio_console_controller_for "Folio::File::Video"

  def subtitles_html
    render_component_json(Folio::Console::Files::HasSubtitlesFormComponent.new(file: @video))
  end

  def retranscribe_subtitles
    @video.transcribe_subtitles!(force: true)
    render_component_json(Folio::Console::Files::HasSubtitlesFormComponent.new(file: @video))
  end

  def update_subtitles
    @video.update(params.require(:file).permit(:subtitles_cs_enabled, :subtitles_cs_text))
    render_component_json(Folio::Console::Files::HasSubtitlesFormComponent.new(file: @video))
  end
end

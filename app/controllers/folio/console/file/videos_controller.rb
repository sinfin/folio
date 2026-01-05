# frozen_string_literal: true

class Folio::Console::File::VideosController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase

  folio_console_controller_for "Folio::File::Video"

  def retranscribe_subtitles
    @video.transcribe_subtitles!(force: true)
    redirect_to action: :show
  end
end

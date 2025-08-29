# frozen_string_literal: true

class Folio::Console::File::VideosController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase

  folio_console_controller_for "Folio::File::Video", except: %w[index]
  authorize_resource class: "Folio::File::Video", only: %i[index]

  def retranscribe_subtitles
    @video.transcribe_subtitles!(force: true)
    redirect_to action: :show
  end
end

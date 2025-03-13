# frozen_string_literal: true

class Folio::Console::File::VideosController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase

  folio_console_controller_for "Folio::File::Video"
end

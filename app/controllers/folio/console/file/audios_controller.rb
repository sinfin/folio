# frozen_string_literal: true

class Folio::Console::File::AudiosController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase

  folio_console_controller_for "Folio::File::Audio"
end

# frozen_string_literal: true

class Folio::Console::Api::File::AudiosController < Folio::Console::Api::BaseController
  include Folio::Console::Api::FileControllerBase

  folio_console_controller_for "Folio::File::Audio"
end

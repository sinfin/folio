# frozen_string_literal: true

class Folio::Console::Api::File::ImagesController < Folio::Console::Api::BaseController
  include Folio::Console::Api::FileControllerBase
  include Folio::Console::Api::ImagesControllerAdditions

  folio_console_controller_for "Folio::File::Image"
end

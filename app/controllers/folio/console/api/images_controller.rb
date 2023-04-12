# frozen_string_literal: true

class Folio::Console::Api::ImagesController < Folio::Console::Api::BaseController
  include Folio::Console::Api::FileControllerBase
  include Folio::Console::Api::ImagesControllerAdditions

  folio_console_controller_for "Folio::Image"
end

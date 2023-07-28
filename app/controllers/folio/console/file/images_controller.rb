# frozen_string_literal: true

class Folio::Console::File::ImagesController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase

  folio_console_controller_for "Folio::File::Image", except: %w[index]
  authorize_resource class: "Folio::File::Image", only: %i[index]
end

# frozen_string_literal: true

class Folio::Console::ImagesController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase

  folio_console_controller_for "Folio::Image", except: %w[index]
  authorize_resource class: "Folio::Image", only: %i[index]

  private
    def image_params
      file_params
    end
end

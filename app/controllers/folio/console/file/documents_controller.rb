# frozen_string_literal: true

class Folio::Console::File::DocumentsController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase

  folio_console_controller_for "Folio::File::Document", except: %w[index]
  authorize_resource class: "Folio::File::Document", only: %i[index]

  private
    def document_params
      file_params
    end
end

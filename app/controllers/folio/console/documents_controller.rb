# frozen_string_literal: true

class Folio::Console::DocumentsController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase

  folio_console_controller_for "Folio::Document", except: %w[index]
  authorize_resource class: "Folio::Document", only: %i[index]

  private
    def document_params
      file_params
    end
end

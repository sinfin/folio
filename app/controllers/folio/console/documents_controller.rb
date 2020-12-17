# frozen_string_literal: true

class Folio::Console::DocumentsController < Folio::Console::BaseController
  include Folio::Console::FileControllerBase
  add_breadcrumb(Folio::Document.model_name.human(count: 2),
                 :console_documents_path)

  private

    def index_path
      console_documents_path
    end

    def find_files
      Folio::Document.ordered
    end
end

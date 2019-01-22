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
      cache_key = ['folio',
                   'console',
                   'documents',
                   Folio::Document.maximum(:updated_at)]

      @files = Rails.cache.fetch(cache_key, expires_in: 1.day) do
        Folio::Document.ordered
                .includes(:tags)
                .includes(:file_placements)
                .all
      end
    end
end

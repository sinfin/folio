# frozen_string_literal: true

module Folio
  class Console::DocumentsController < Console::BaseController
    include Console::FileControllerBase
    add_breadcrumb Document.model_name.human(count: 2), :console_documents_path

    private

      def index_path
        console_documents_path
      end

      def find_files
        cache_key = ['folio',
                     'console',
                     'documents',
                     Document.maximum(:updated_at)]

        @files = Rails.cache.fetch(cache_key, expires_in: 1.day) do
          Document.ordered
                  .includes(:tags)
                  .includes(:file_placements)
                  .all
        end
      end
  end
end

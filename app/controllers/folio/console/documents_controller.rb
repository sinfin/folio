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
        @files = Document.ordered
      end
  end
end

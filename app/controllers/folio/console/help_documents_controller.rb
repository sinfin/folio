# frozen_string_literal: true

module Folio
  module Console
    class HelpDocumentsController < BaseController
      def index
        @help_documents = Folio::HelpDocument.all
      end

      def show
        @help_document = Folio::HelpDocument.find(params[:id])
        unless @help_document
          flash[:danger] = t(".not_found")
          redirect_to console_help_documents_path
        end
      end
    end
  end
end 
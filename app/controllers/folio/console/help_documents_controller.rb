# frozen_string_literal: true

class Folio::Console::HelpDocumentsController < Folio::Console::BaseController
  before_action :authorize_help_documents_access!

  def index
    @help_documents = Folio::HelpDocument.all
  end

  def show
    @help_document = Folio::HelpDocument.find(params[:id])
    unless @help_document
      flash[:danger] = t(".not_found")
      redirect_to console_help_documents_path
      nil
    end
  end

  private
    def authorize_help_documents_access!
      authorize! :access_help_documents, Folio::Current.site
    end
end

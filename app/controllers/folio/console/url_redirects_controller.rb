# frozen_string_literal: true

class Folio::Console::UrlRedirectsController < Folio::Console::BaseController
  folio_console_controller_for "Folio::UrlRedirect"

  private
    def url_redirect_params
      params.require(:folio_url_redirect)
            .permit(*(@klass.column_names - %w[id site_id]))
    end

    def index_filters
      {}
    end

    def folio_console_collection_includes
      []
    end
end

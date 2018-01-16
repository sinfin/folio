# frozen_string_literal: true

module Folio
  class Console::VisitsController < Console::BaseController
    load_and_authorize_resource

    add_breadcrumb(I18n.t('folio.console.visits.index.title'),
                   :console_visits_path)

    def index
      @visits = @visits.filter(filter_params) if params[:by_query].present?
      @visits = @visits.page(current_page)
    end

    def show
    end

    private
      def filter_params
        params.permit(:by_query)
      end
  end
end

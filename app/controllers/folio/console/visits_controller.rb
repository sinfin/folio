# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class Console::VisitsController < Console::BaseController
    load_and_authorize_resource

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

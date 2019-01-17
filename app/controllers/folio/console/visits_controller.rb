# frozen_string_literal: true

class Folio::Console::VisitsController < Folio::Console::BaseController
  load_and_authorize_resource
  add_breadcrumb Visit.model_name.human(count: 2), :console_visits_path

  def index
    @visits = @visits.filter_by_params(filter_params) if params[:by_query].present?
    @visits = @visits.page(current_page)
  end

  def show
  end

  private

    def filter_params
      params.permit(:by_query)
    end
end

# frozen_string_literal: true

class Folio::Console::VisitsController < Folio::Console::BaseController
  load_and_authorize_resource
  add_breadcrumb Visit.model_name.human(count: 2), :console_visits_path

  def index
    @pagy, @visits = pagy(@visits)
  end

  def show
  end
end

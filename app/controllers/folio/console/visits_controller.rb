# frozen_string_literal: true

class Folio::Console::VisitsController < Folio::Console::BaseController
  folio_console_controller_for "Visit"

  def index
    @pagy, @visits = pagy(@visits.includes(:ahoy_events))
  end
end

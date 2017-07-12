# frozen_string_literal: true

require_dependency 'folio/application_controller'

module Folio
  class Console::DashboardController < Console::BaseController
    def index
      redirect_to console_nodes_path
    end
  end
end

# frozen_string_literal: true

module Folio
  class Console::DashboardController < Console::BaseController
    def index
      redirect_to console_nodes_path
    end
  end
end

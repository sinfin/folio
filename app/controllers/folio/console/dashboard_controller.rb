# frozen_string_literal: true

class Folio::Console::DashboardController < Folio::Console::BaseController
  def index
    if path = current_site.console_dashboard_redirect_path_name
      if respond_to?(path)
        redirect_to send(path)
      elsif main_app.respond_to?(path)
        redirect_to main_app.send(path)
      end
    end
  end
end

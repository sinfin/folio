# frozen_string_literal: true

class Folio::Console::Api::CurrentUsersController < Folio::Console::Api::BaseController
  def console_url_ping
    current_user.update_console_url!(params.require(:url))
    head 200
  end
end

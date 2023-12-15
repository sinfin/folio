# frozen_string_literal: true

class Folio::Console::Api::CurrentAccountsController < Folio::Console::Api::BaseController
  def console_path_ping
    current_user.update_console_path!(params.require(:path))
    head 200
  end
end

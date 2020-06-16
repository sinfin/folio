# frozen_string_literal: true

class Folio::Console::Layout::HeaderCell < Folio::ConsoleCell
  def log_out_path
    options[:log_out_path] || controller.destroy_account_session_path
  end
end

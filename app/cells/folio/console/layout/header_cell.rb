# frozen_string_literal: true

class Folio::Console::Layout::HeaderCell < Folio::ConsoleCell
  def log_out_path
    if options[:log_out_path]
      controller.send(options[:log_out_path])
    else
      controller.destroy_account_session_path
    end
  end
end

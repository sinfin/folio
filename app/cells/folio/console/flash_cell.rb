# frozen_string_literal: true

class Folio::Console::FlashCell < Folio::ConsoleCell
  VARIANTS = {
    alert: :danger,
    error: :danger,
    warning: :warning,
    notice: :info,
    success: :success,
    loader: :loader,
  }
end

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

  def flashes
    if model.present?
      # filter out devise timedout
      # https://github.com/heartcombo/devise/issues/1777
      model.filter { |key, _value| key != "timedout" }
    else
      []
    end
  end
end

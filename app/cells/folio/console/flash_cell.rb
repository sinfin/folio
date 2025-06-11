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
      # filter out devise timedout (https://github.com/heartcombo/devise/issues/1777) and autohide
      model.filter { |key, _value| key != "timedout" && key != "autohide" }
    else
      []
    end
  end

  def autohide?
    model.present? && (model["autohide"] || model[:autohide])
  end
end

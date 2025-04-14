# frozen_string_literal: true

class Folio::Console::Ui::FlashComponent < Folio::Console::ApplicationComponent
  VARIANTS = {
    alert: :danger,
    error: :danger,
    warning: :warning,
    notice: :info,
    success: :success,
    loader: :loader,
  }

  def initialize(flash:)
    @flash = flash
  end
end

# frozen_string_literal: true

class Dummy::Ui::FlashComponent < ApplicationComponent
  VARIANTS = {
    alert: :danger,
    error: :danger,
    loader: :loader,
    notice: :info,
    dark: :dark,
    success: :success,
    warning: :warning,
  }

  def initialize(flash:)
    @flash = flash
  end

  def variant(type)
    VARIANTS[type.to_sym]
  end
end

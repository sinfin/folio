# frozen_string_literal: true

class Dummy::Ui::FlashComponent < ApplicationComponent
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

  def variant(type)
    VARIANTS[type.to_sym]
  end
end

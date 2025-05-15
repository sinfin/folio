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
    @flash = if flash.present?
      # filter out devise timedout
      # https://github.com/heartcombo/devise/issues/1777
      flash.filter { |key, _value| key != "timedout" }
    else
      []
    end
  end

  def variant(type)
    VARIANTS[type.to_sym]
  end
end

# frozen_string_literal: true

class Dummy::Ui::AlertComponent < ApplicationComponent
  bem_class_name :flash, :closable

  def initialize(message:, variant: :info, flash: false, closable: true)
    @message = message
    @variant = variant
    @flash = flash
    @closable = closable
  end

  def icon_key
    case @variant
    when :success
      :check
    when :warning, :danger
      :alert_triangle
    else
      :info
    end
  end
end

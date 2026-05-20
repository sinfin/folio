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

  RESERVED_FLASH_KEYS = %w[timedout autohide alert_stimulus_controllers alert_data].freeze

  def initialize(flash:)
    flash_hash = flash.present? ? flash : nil

    @autohide = flash_hash && (flash_hash["autohide"] || flash_hash[:autohide]) ? true : false
    @alert_stimulus_controllers = flash_hash ? Array.wrap(flash_hash["alert_stimulus_controllers"] || flash_hash[:alert_stimulus_controllers]) : []
    @alert_data = flash_hash ? (flash_hash["alert_data"] || flash_hash[:alert_data] || {}) : {}

    @flash = if flash_hash
      flash_hash.filter { |key, _value| !RESERVED_FLASH_KEYS.include?(key.to_s) }
    else
      flash
    end
  end

  attr_reader :autohide, :alert_stimulus_controllers, :alert_data
end

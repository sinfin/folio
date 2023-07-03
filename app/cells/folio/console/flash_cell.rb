# frozen_string_literal: true

class Folio::Console::FlashCell < Folio::ConsoleCell
  BOOTSTRAP_CLASSES = {
    success: "alert-success",
    error: "alert-danger",
    alert: "alert-warning",
    info: "alert-info",
    pending: "alert-pending",
    notice: "alert-success"
  }.freeze

  def bootstrap_class_for(msg_type)
    BOOTSTRAP_CLASSES[msg_type.to_sym] || msg_type
  end

  def flash_icon_key(msg_type)
    case msg_type.to_sym
    when :success
      :check_circle_outline
    when :info, :notice
      :information_outline
    else
      :alert
    end
  end
end

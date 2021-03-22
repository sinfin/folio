# frozen_string_literal: true

class Dummy::Ui::FlashCell < ApplicationCell
  BOOTSTRAP_CLASSES = {
    alert: "alert-danger",
    error: "alert-danger",
    notice: "alert-info",
    success: "alert-success",
    warning: "alert-warning",
  }.freeze

  ICONS = {
    alert: "warning",
    error: "warning",
    notice: "info",
    success: "check_circle",
    warning: "warning",
  }.freeze

  def bootstrap_class_for(msg_type)
    BOOTSTRAP_CLASSES[msg_type.to_sym] || msg_type
  end

  def icon_for(msg_type)
    ICONS[msg_type.to_sym]
  end
end

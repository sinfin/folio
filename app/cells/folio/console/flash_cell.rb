# frozen_string_literal: true

class Folio::Console::FlashCell < Folio::ConsoleCell
  BOOTSTRAP_CLASSES = {
    success: "alert-success",
    error: "alert-danger",
    alert: "alert-warning",
    notice: "alert-success"
  }.freeze

  def bootstrap_class_for(msg_type)
    BOOTSTRAP_CLASSES[msg_type.to_sym] || msg_type
  end

  FA_ICONS = {
    success: "fa fa-mr fa-check-circle",
    error: "fa fa-mr fa-times-circle",
    alert: "fa fa-mr fa-times-circle",
    notice: "fa fa-mr fa-info-circle"
  }.freeze

  def fa_icon_for(msg_type)
    FA_ICONS[msg_type.to_sym] || msg_type
  end
end

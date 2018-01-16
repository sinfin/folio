# frozen_string_literal: true

class Folio::Console::FlashCell < FolioCell
  def show
    if model.blank?
      ''
    else
      render
    end
  end

  BOOTSTRAP_CLASSES = {
    success: 'alert-success',
    error: 'alert-danger',
    alert: 'alert-warning',
    notice: 'alert-info'
  }.freeze

  def bootstrap_class_for(msg_type)
    BOOTSTRAP_CLASSES[msg_type.to_sym] || msg_type
  end

  FA_ICONS = {
    success: 'fa fa-check-circle',
    error: 'fa fa-times-circle',
    alert: 'fa fa-times-circle',
    notice: 'fa fa-info-circle'
  }.freeze

  def fa_icon_for(msg_type)
    FA_ICONS[msg_type.to_sym] || msg_type
  end
end

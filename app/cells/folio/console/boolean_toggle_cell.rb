# frozen_string_literal: true

class Folio::Console::BooleanToggleCell < FolioCell
  ATTRIBUTE = :published
  ICON_ON = 'toggle-on'
  ICON_OFF = 'toggle-off'

  def form(&block)
    form_with(model: model, as: options[:as], url: url) do
      yield(block)
    end
  end

  def as
    options[:as] || model.class.table_name.singularize
  end

  def attr
    options[:attr] || self.class::ATTRIBUTE
  end

  def attr_name
    "#{as}[#{attr}]"
  end

  def value
    model.send(attr)
  end

  def icon_on
    "fa-#{self.class::ICON_ON}"
  end

  def icon_off
    "fa-#{self.class::ICON_OFF}"
  end

  def model_url
    options[:url] || "console_#{as}_path"
  end

  def url
    controller.try(model_url, model.id, format: :json) ||
    controller.main_app.public_send(model_url, model.id, format: :json)
  end
end

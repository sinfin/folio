# frozen_string_literal: true

class Folio::Console::BooleanToggleCell < Folio::ConsoleCell
  ATTRIBUTE = :published
  ICON_ON = 'toggle-on'
  ICON_OFF = 'toggle-off'

  def show
    render if url.present?
  end

  def form(&block)
    form_with(model: model, as: as, url: url) do
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

  def url
    return options[:url] if options[:url].present?
    model_url = "console_#{as}_path"
    public_send(model_url, model.id, format: :json)
  rescue NoMethodError
    controller.public_send(model_url, model.id, format: :json)
  rescue ActionController::UrlGenerationError
    controller.main_app.public_send(model_url, model.id, format: :json)
  rescue StandardError
    nil
  end
end

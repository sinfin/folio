# frozen_string_literal: true

class Folio::Console::BooleanToggleCell < Folio::ConsoleCell
  class_name "f-c-boolean-toggle", :show_label

  def show
    render if attribute.present? && url.present?
  end

  def attribute
    options[:attribute]
  end

  def url
    options[:url] || url_for([:console, model, format: :json])
  rescue StandardError
    nil
  end

  def id
    "f-c-boolean-toggle--#{model.try(:id)}-#{attribute}"
  end

  def input_label
    if options[:show_label]
      "#{options[:show_label]}:"
    else
      ""
    end
  end

  def input_checked?
    !!model.try(attribute)
  end

  def name
    "#{as}[#{attribute}]"
  end

  def as
    options[:as] || model.class.model_name.param_key
  end
end

# frozen_string_literal: true

class Folio::Console::BooleanToggleCell < Folio::ConsoleCell
  def show
    render if url.present?
  end

  def form(&block)
    form_with(model: model, as: as, url: url) do
      yield(block)
    end
  end

  def as
    options[:as] || model.class.table_name.singularize.gsub('folio_', '')
  end

  def attribute
    options[:attribute]
  end

  def attr_name
    "#{as}[#{attribute}]"
  end

  def value
    model.send(attribute)
  end

  def url
    controller.url_for([:console, model, format: :json])
  rescue StandardError
    nil
  end

  def id
    "f-c-boolean-toggle--#{model.id}-#{attribute}"
  end
end

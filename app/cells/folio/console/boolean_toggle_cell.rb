# frozen_string_literal: true

class Folio::Console::BooleanToggleCell < Folio::ConsoleCell
  class_name "f-c-boolean-toggle", :show_label, :verbose

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
    uniq = "#{model.class.try(:table_name)}-#{model.try(:id)}"
    "f-c-boolean-toggle--#{uniq}-#{attribute}"
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

  def verbose_label(boolean)
    model.class.human_attribute_name("#{attribute}/#{boolean}")
  end

  def input_data_confirmation
    if options[:confirm].is_a?(String)
      options[:confirm]
    elsif options[:confirm]
      t("folio.console.confirmation")
    end
  end

  def input_data
    {
      url:,
      confirmation: input_data_confirmation,
      action: "f-c-boolean-toggle#inputChange",
      "f-c-boolean-toggle-target" => "input",
    }.compact
  end
end

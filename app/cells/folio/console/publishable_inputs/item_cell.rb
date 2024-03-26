# frozen_string_literal: true

class Folio::Console::PublishableInputs::ItemCell < Folio::ConsoleCell
  class_name "f-c-publishable-inputs-item", :date?, :active?

  def f
    model[:f]
  end

  def field
    model[:field]
  end

  def date_at?
    return @date_at unless @date_at.nil?
    @date_at = f.object.respond_to?("#{field}_at")
  end

  def date_between?
    return @date_between unless @date_between.nil?
    @date_between = f.object.respond_to?("#{field}_from") && f.object.respond_to?("#{field}_until")
  end

  def date?
    date_at? || date_between?
  end

  def active?
    !!f.object.send(field)
  end

  def can_field?
    field != :published || controller.can_now?(:publish, f.object)
  end

  def input_html(class_name_element = nil, placeholder: nil, checkbox: false)
    b = { class: class_name_element ? "f-c-publishable-inputs-item__#{class_name_element}" : nil }

    b[:id] = nil if options[:no_input_ids]
    b[:name] = nil if options[:no_input_names]
    b[:placeholder] = placeholder

    if checkbox
      b["data-action"] = "f-c-publishable-inputs-item#onCheckboxChange"
    end

    b
  end

  def data
    {
      controller: "f-c-publishable-inputs-item"
    }
  end

  def wrapper_html
    { class: "f-c-publishable-inputs-item__wrapper" }
  end
end

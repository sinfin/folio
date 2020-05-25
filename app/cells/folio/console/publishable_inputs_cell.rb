# frozen_string_literal: true

class Folio::Console::PublishableInputsCell < Folio::ConsoleCell
  def f
    model
  end

  def input_html(class_name = nil, placeholder: nil)
    b = { class: class_name }
    b[:id] = nil if options[:no_input_ids]
    b[:name] = nil if options[:no_input_names]
    b[:placeholder] = placeholder
    b
  end

  def publishable_with_date?
    f.object.respond_to?(:published_at)
  end

  def publishable_within?
    f.object.respond_to?(:published_from) && f.object.respond_to?(:published_until)
  end

  def featurable_within?
    f.object.respond_to?(:featured_from) && f.object.respond_to?(:featured_until)
  end
end

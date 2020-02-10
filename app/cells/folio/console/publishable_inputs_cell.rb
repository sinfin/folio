# frozen_string_literal: true

class Folio::Console::PublishableInputsCell < Folio::ConsoleCell
  def f
    model
  end

  def input_html(class_name = nil)
    b = { class: class_name }
    b[:id] = nil if options[:no_input_ids]
    b[:name] = nil if options[:no_input_names]
    b
  end
end

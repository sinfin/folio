# frozen_string_literal: true

class Folio::Console::PublishableInputsCell < Folio::ConsoleCell
  def f
    model
  end

  def input_html(class_name = nil)
    if options[:no_input_ids]
      { id: nil, class: class_name }
    else
      { class: class_name }
    end
  end
end

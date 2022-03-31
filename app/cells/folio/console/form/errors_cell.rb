# frozen_string_literal: true

class Folio::Console::Form::ErrorsCell < Folio::ConsoleCell
  def show
    render if errors.present?
  end

  def errors
    options[:errors] || model.object.errors
  end

  def dig_error_message(error)
    if ie = error.try(:inner_error)
      dig_error_message(ie)
    else
      error.full_message
    end
  end
end

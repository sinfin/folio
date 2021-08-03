# frozen_string_literal: true

class Folio::Console::Form::ErrorsCell < Folio::ConsoleCell
  def show
    render if errors.present?
  end

  def errors
    options[:errors] || model.object.errors
  end
end

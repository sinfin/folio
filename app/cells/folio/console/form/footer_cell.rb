# frozen_string_literal: true

class Folio::Console::Form::FooterCell < Folio::ConsoleCell
  class_name 'f-c-form-footer', :static

  def back_path
    options[:back_path] || controller.url_for([:console, model.object.class])
  end
end

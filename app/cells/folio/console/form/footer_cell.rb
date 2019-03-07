# frozen_string_literal: true

class Folio::Console::Form::FooterCell < Folio::ConsoleCell
  class_name 'f-c-form-footer', :static

  def back_path
    options[:back_path] ||
    referer ||
    controller.url_for([:console, model.object.class])
  rescue NoMethodError
  end

  def referer
    if request.referer && request.referer != request.url
      request.referer
    end
  end
end

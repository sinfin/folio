# frozen_string_literal: true

class Folio::Console::Form::FooterCell < Folio::ConsoleCell
  class_name 'f-c-form-footer', :static

  def back_path
    options[:back_path] || controller.url_for([:console, model.object.class])
  rescue NoMethodError
  end

  def submit_label
    if options[:submit_continue]
      t('folio.console.actions.continue')
    elsif options[:submit_label].present?
      options[:submit_label]
    else
      t('folio.console.actions.submit')
    end
  end
end

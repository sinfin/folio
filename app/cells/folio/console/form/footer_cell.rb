# frozen_string_literal: true

class Folio::Console::Form::FooterCell < Folio::ConsoleCell
  def back_path
    options[:back_path] || url_for([:console, model.object.class])
  rescue NoMethodError
  end

  def preview_path
    return nil unless model
    return nil unless model.object.persisted?
    return nil if options[:preview_button] == false
    return options[:preview_path]  if options[:preview_path]

    if model.object.respond_to?(:published?) && token = model.object.try(:preview_token)
      url_for([model.object, Folio::Publishable::PREVIEW_PARAM_NAME => token])
    else
      url_for(model.object)
    end
  rescue NoMethodError
  end

  def submit_label
    if options[:submit_continue]
      t("folio.console.actions.continue")
    elsif options[:submit_label].present?
      options[:submit_label]
    else
      t("folio.console.actions.submit")
    end
  end
end

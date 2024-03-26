# frozen_string_literal: true

class Folio::Console::Form::FooterCell < Folio::ConsoleCell
  def back_path
    return if options[:back_button] == false

    options[:back_path] || through_aware_console_url_for(model.object.class, safe: true)
  end

  def preview_path
    return if options[:preview_button] == false
    return options[:preview_path] if options[:preview_path]

    return unless model
    return unless model.object.persisted?

    options[:preview_path] || preview_url_for(model.object)
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

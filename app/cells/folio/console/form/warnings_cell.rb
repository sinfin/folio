# frozen_string_literal: true

class Folio::Console::Form::WarningsCell < Folio::ConsoleCell
  def show
    return unless warnings.present?
    render
  end

  def warnings
    options[:warnings] || []
  end

  def notification
    I18n.t("folio.console.form.warnings.notification")
  end

  def key
    options[:record_key] || controller.controller_path
  end
end

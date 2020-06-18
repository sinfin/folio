# frozen_string_literal: true

class Folio::Console::PrivateAttachments::ListCell < Folio::ConsoleCell
  def download_url(pa)
    controller.folio.download_path(pa, pa.file_name, locale: I18n.locale)
  rescue StandardError
    controller.download_path(pa, pa.file_name, locale: I18n.locale)
  end
end

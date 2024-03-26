# frozen_string_literal: true

class Folio::Console::Ui::FlagCell < Folio::ConsoleCell
  CDN = "https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags"

  def code
    @code ||= (Folio::LANGUAGES[model.to_sym] || model).downcase
  end
end

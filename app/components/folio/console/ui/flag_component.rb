# frozen_string_literal: true

class Folio::Console::Ui::FlagComponent < Folio::Console::ApplicationComponent
  CDN = "https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags"

  def initialize(locale:)
    @locale = locale
  end

  def code
    @code ||= (Folio::LANGUAGES[@locale.to_sym] || @locale).downcase
  end
end

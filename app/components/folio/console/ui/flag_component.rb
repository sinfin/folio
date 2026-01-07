# frozen_string_literal: true

class Folio::Console::Ui::FlagComponent < Folio::Console::ApplicationComponent
  CDN = "https://cdnjs.cloudflare.com/ajax/libs/flag-icon-css/6.7.0/flags"

  def initialize(code:)
    @code = code
  end

  def normalized_code
    @normalized_code ||= (Folio::LANGUAGES[@code.to_sym] || @code).downcase
  end
end

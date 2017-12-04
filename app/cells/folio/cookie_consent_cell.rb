# frozen_string_literal: true

class Folio::CookieConsentCell < FolioCell
  def position
    model || 'bottom'
  end
end

class Folio::CookieConsentCell < FolioCell
  def position
    model || 'bottom'
  end
end

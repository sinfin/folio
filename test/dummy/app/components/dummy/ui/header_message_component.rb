# frozen_string_literal: true

class Dummy::Ui::HeaderMessageComponent < ApplicationComponent
  def message
    @message ||= if Folio::Current.site.header_message_published?
      if controller.send(:cookies)[:hiddenHeaderMessage] != cookie
        Folio::Current.site.header_message.presence
      end
    end
  end

  def cookie
    @cookie ||= Base64.urlsafe_encode64(Folio::Current.site.header_message)
  end
end

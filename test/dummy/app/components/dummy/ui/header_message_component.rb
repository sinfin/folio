# frozen_string_literal: true

class Dummy::Ui::HeaderMessageComponent < ApplicationComponent
  def message
    @message ||= if current_site.header_message_published?
      if controller.send(:cookies)[:hiddenHeaderMessage] != cookie
        current_site.header_message.presence
      end
    end
  end

  def cookie
    @cookie ||= Base64.urlsafe_encode64(current_site.header_message)
  end
end

# frozen_string_literal: true

class Dummy::Ui::HeaderMessageCell < ApplicationCell
  def show
    return nil if message.blank?
    render if controller.send(:cookies)[:hiddenHeaderMessage] != cookie
  rescue StandardError
    render if message.present?
  end

  def message
    @message ||= model.header_message_published? ? model.header_message.presence : nil
  end

  def cookie
    @cookie ||= Base64.urlsafe_encode64(model.header_message)
  end
end

# frozen_string_literal: true

module Folio::HasHeaderMessage
  extend ActiveSupport::Concern

  def header_message_published?
    if header_message_published.present?
      if header_message_published_from.present? && header_message_published_from >= Time.zone.now
        return false
      end

      if header_message_published_until.present? && header_message_published_until <= Time.zone.now
        return false
      end

      true
    else
      false
    end
  end
end

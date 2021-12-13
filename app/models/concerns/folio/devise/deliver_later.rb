# frozen_string_literal: true

module Folio::Devise::DeliverLater
  extend ActiveSupport::Concern

  # the devise commented-out way via "pending_devise_notifications" doesn't work for password reset

  included do
    protected
      def send_devise_notification(notification, *args)
        devise_mailer.send(notification, self, *args).deliver_later
      end
  end
end

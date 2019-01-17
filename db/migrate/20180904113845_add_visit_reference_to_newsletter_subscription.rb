# frozen_string_literal: true

class AddVisitReferenceToNewsletterSubscription < ActiveRecord::Migration[5.2]
  def change
    add_reference :folio_newsletter_subscriptions, :visit
  end
end

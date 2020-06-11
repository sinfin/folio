# frozen_string_literal: true

class AddMailchimpTagsToFolioNewsletterSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_newsletter_subscriptions, :mailchimp_tags, :string
  end
end

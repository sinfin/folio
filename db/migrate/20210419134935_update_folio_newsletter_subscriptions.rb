# frozen_string_literal: true

class UpdateFolioNewsletterSubscriptions < ActiveRecord::Migration[6.0]
  def change
    unless column_exists?(:folio_users, :subscribed_to_newsletter)
      add_column :folio_users, :subscribed_to_newsletter, :boolean, default: false
    end

    add_reference :folio_newsletter_subscriptions, :subscribable, polymorphic: true, index: { name: "index_folio_newsletter_subscriptions_on_subscribable" }
    add_column :folio_newsletter_subscriptions, :active, :boolean, default: true
    add_column :folio_newsletter_subscriptions, :tags, :string
    add_column :folio_newsletter_subscriptions, :merge_vars, :text
  end
end

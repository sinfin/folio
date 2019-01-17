# frozen_string_literal: true

class CreateFolioNewsletterSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :folio_newsletter_subscriptions do |t|
      t.string :email

      t.timestamps
    end
  end
end

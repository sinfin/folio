# frozen_string_literal: true

class DropUnwantedAhoy < ActiveRecord::Migration[6.0]
  def up
    %i[folio_leads folio_newsletter_subscriptions folio_session_attachments].each do |key|
      if column_exists?(key, :visit_id)
        remove_reference key, :visit
      end
    end

    if !defined?(Visit) && table_exists?(:visits)
      drop_table :visits
    end

    if !defined?(Ahoy::Event) && table_exists?(:ahoy_events)
      drop_table :ahoy_events
    end
  end

  def down
    if defined?(Visit) && !table_exists?(:visits)
      create_table :visits do |t|
        t.string :visit_token
        t.string :visitor_token

        # the rest are recommended but optional
        # simply remove the columns you don't want

        # standard
        t.string :ip
        t.text :user_agent
        t.text :referrer
        t.text :landing_page

        # site
        t.belongs_to :site

        # user
        t.belongs_to :account
        # add t.string :user_type if polymorphic

        # traffic source
        t.string :referring_domain
        t.string :search_keyword

        # technology
        t.string :browser
        t.string :os
        t.string :device_type
        t.integer :screen_height
        t.integer :screen_width

        # location
        t.string :country
        t.string :region
        t.string :city
        t.string :postal_code
        t.decimal :latitude
        t.decimal :longitude

        # utm parameters
        t.string :utm_source
        t.string :utm_medium
        t.string :utm_term
        t.string :utm_content
        t.string :utm_campaign

        # native apps
        # t.string :platform
        # t.string :app_version
        # t.string :os_version

        t.timestamp :started_at
      end

      add_index :visits, [:visit_token], unique: true
    end

    if defined?(Ahoy::Event) && !table_exists?(:ahoy_events)
      create_table :ahoy_events do |t|
        t.integer :visit_id

        # user
        t.belongs_to :account
        # add t.string :user_type if polymorphic

        t.string :name
        t.jsonb :properties
        t.timestamp :time
      end

      add_index :ahoy_events, [:visit_id, :name]
      add_index :ahoy_events, [:name, :time]
    end
  end
end

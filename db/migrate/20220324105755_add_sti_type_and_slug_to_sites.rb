# frozen_string_literal: true

class AddStiTypeAndSlugToSites < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_sites, :type, :string
    add_index :folio_sites, :type

    add_column :folio_sites, :slug, :string
    add_index :folio_sites, :slug

    add_column :folio_sites, :position, :integer
    add_index :folio_sites, :position

    add_reference :folio_email_templates, :site
    add_reference :folio_leads, :site
    add_reference :folio_menus, :site
    add_reference :folio_newsletter_subscriptions, :site
    add_reference :folio_pages, :site
  end
end

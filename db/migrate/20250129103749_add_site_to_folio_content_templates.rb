# frozen_string_literal: true

class AddSiteToFolioContentTemplates < ActiveRecord::Migration[7.1]
  def up
    add_reference :folio_content_templates, :site, foreign_key: { to_table: :folio_sites }, index: true, null: true

    site_ids = Folio::Site.pluck(:id)

    # Duplicate existing content templates for each site
    Folio::ContentTemplate.find_each do |template|
      site_ids.each do |site_id|
        Folio::ContentTemplate.create!(template.attributes.except("id", "created_at", "updated_at").merge(site_id:))
      end
    end

    Folio::ContentTemplate.where(site_id: nil).delete_all

    change_column_null :folio_content_templates, :site_id, false
  end

  def down
    remove_column :folio_content_templates, :site_id
  end
end

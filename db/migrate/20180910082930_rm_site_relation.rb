# frozen_string_literal: true

class RmSiteRelation < ActiveRecord::Migration[5.2]
  def change
    remove_reference :folio_nodes, :site

    if table_exists?(:visits) && column_exists?(:visits, :site_id)
      remove_reference :visits, :site
    end
  end
end

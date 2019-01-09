class RmSiteRelation < ActiveRecord::Migration[5.2]
  def change
    remove_reference :folio_nodes, :site

    if column_exists?(:visits, :site_id)
      remove_reference :visits, :site
    end
  end
end

class RmSiteRelation < ActiveRecord::Migration[5.2]
  def change
    remove_reference :folio_nodes, :site
    remove_reference :visits, :site
  end
end

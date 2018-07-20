class AddVisitReferenceToLead < ActiveRecord::Migration[5.1]
  def change
    add_reference :folio_leads, :visit
  end
end

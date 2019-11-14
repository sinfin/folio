# frozen_string_literal: true

class UseAasmForLeads < ActiveRecord::Migration[5.2]
  def change
    rename_column :folio_leads, :state, :aasm_state
  end
end

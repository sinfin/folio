# frozen_string_literal: true

class RmSiteTurboMode < ActiveRecord::Migration[6.0]
  def change
    remove_column :folio_sites, :turbo_mode
  end
end

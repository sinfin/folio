# frozen_string_literal: true

class RmSiteLocaleDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:folio_sites, :locale, nil)
  end
end

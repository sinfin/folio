# frozen_string_literal: true

class RmPagesFeatured < ActiveRecord::Migration[7.0]
  def change
    remove_index :folio_pages, :featured
    remove_column :folio_pages, :featured, :boolean
  end
end

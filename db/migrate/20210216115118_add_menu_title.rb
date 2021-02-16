# frozen_string_literal: true

class AddMenuTitle < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_menus, :title, :string
  end
end

# frozen_string_literal: true

class AddDefaultGravityToFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_files, :default_gravity, :string
  end
end

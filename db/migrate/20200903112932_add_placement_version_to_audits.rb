# frozen_string_literal: true

class AddPlacementVersionToAudits < ActiveRecord::Migration[6.0]
  def change
    add_column :audits, :placement_version, :integer
    add_index :audits, :placement_version
  end
end

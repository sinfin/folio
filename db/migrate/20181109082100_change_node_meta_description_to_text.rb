# frozen_string_literal: true

class ChangeNodeMetaDescriptionToText < ActiveRecord::Migration[5.2]
  def change
    change_column :folio_nodes, :meta_description, :text
  end
end

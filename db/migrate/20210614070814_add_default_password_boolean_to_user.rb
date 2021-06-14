# frozen_string_literal: true

class AddDefaultPasswordBooleanToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_users, :has_generated_password, :boolean, default: false
  end
end

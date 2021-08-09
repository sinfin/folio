# frozen_string_literal: true

class AddPhoneToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :folio_users, :phone, :string
  end
end

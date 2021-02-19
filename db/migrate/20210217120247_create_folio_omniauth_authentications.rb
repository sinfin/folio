# frozen_string_literal: true

class CreateFolioOmniauthAuthentications < ActiveRecord::Migration[6.0]
  def change
    create_table :folio_omniauth_authentications do |t|
      t.belongs_to :folio_user

      t.string :uid
      t.string :provider

      t.string :email
      t.string :nickname
      t.string :access_token

      t.json :raw_info

      t.string :conflict_token
      t.integer :conflict_user_id

      t.timestamps
    end

    add_column :folio_users, :nickname, :string
  end
end

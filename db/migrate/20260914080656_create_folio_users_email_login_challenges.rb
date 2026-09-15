# frozen_string_literal: true

class CreateFolioUsersEmailLoginChallenges < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_users, :email_authentication_version, :integer, null: false, default: 0

    create_table :folio_users_email_login_challenges do |t|
      t.references :user, null: false, foreign_key: { to_table: :folio_users }
      t.references :site, null: false, foreign_key: { to_table: :folio_sites }
      t.string :purpose, null: false
      t.string :token_digest, null: false
      t.string :browser_nonce_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :approved_at
      t.datetime :consumed_at
      t.datetime :revoked_at
      t.integer :authentication_version, null: false
      t.string :return_path
      t.boolean :remember_me, null: false, default: false
      t.boolean :trust_browser, null: false, default: true
      t.timestamps
    end

    add_index :folio_users_email_login_challenges, :token_digest, unique: true
    add_index :folio_users_email_login_challenges, :expires_at
    add_index :folio_users_email_login_challenges, [:user_id, :site_id, :created_at], name: :index_folio_email_login_deliveries

    create_table :folio_users_trusted_browsers do |t|
      t.references :user, null: false, foreign_key: { to_table: :folio_users }
      t.references :site, null: false, foreign_key: { to_table: :folio_sites }
      t.string :token_digest, null: false
      t.datetime :verified_at, null: false
      t.datetime :last_authenticated_at, null: false
      t.datetime :revoked_at
      t.integer :authentication_version, null: false
      t.timestamps
    end

    add_index :folio_users_trusted_browsers, :token_digest, unique: true
    add_index :folio_users_trusted_browsers, :last_authenticated_at
  end
end

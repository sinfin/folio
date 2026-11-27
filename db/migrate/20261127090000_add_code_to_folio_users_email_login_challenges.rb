# frozen_string_literal: true

class AddCodeToFolioUsersEmailLoginChallenges < ActiveRecord::Migration[7.1]
  def change
    add_column :folio_users_email_login_challenges, :code_digest, :string
    add_column :folio_users_email_login_challenges, :code_attempts, :integer, null: false, default: 0
  end
end

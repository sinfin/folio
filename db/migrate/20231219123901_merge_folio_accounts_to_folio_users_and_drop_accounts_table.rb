# frozen_string_literal: true

class MergeFolioAccountsToFolioUsersAndDropAccountsTable < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.connection_pool.with_connection do
      sites = Folio::Site.all.to_a

      accounts = connection.select_all("SELECT * FROM folio_accounts")

      accounts.each do |account|
        roles_to_pass = JSON.parse(account["roles"])
        superadmin = roles_to_pass.delete("superuser").present?

        user = Folio::User.find_by(email: account["email"])

        if user.blank?
          puts("Creating user for account #{account["email"]}")
          except_attributes = %w[id roles is_active]
          new_attrs = account.except(*except_attributes)
          new_attrs["encrypted_password"] = account["encrypted_password"]
          new_attrs["superadmin"] = superadmin
          new_attrs["confirmed_at"] = Time.current

          # `user = Folio::User.create!(new_attrs)` will somehow stuck db:schema:dump AFTER migration is completed
          insert_sql = "INSERT INTO folio_users (#{new_attrs.keys.join(", ")}) " \
                       " VALUES (#{new_attrs.values.map { |v| (v.nil? ? "NULL" : "'#{v}'") }.join(", ")}) " \
                       " RETURNING id"
          user_id = connection.execute(insert_sql).first["id"]

          user = Folio::User.find(user_id)
          raise "errors on user ##{user.id}[#{user.email}; #{user.errors.full_messages}" unless user.valid?
        else
          puts("User with email #{account["email"]} already exists")
          user.update!(superadmin:)
        end

        sites.each do |site|
          site.available_user_roles ||= []

          missing_site_roles = (roles_to_pass - site.available_user_roles)

          if missing_site_roles.present?
            site.available_user_roles += missing_site_roles
            site.save!
          end

          user.set_roles_for(site:, roles: roles_to_pass)

          raise "errors on user ##{user.id}[#{user.email}; #{account["roles"]}; #{site.domain}]: #{user.errors.full_messages}" unless user.save
        end

        Folio::ConsoleNote.where(created_by_id: account["id"]).update_all(created_by_id: user.id)
        Folio::ConsoleNote.where(closed_by_id: account["id"]).update_all(closed_by_id: user.id)
        if defined?(Audited::Audit)
          Audited::Audit.where(user_type: "Folio::Account", user_id: account["id"]).update_all(user_type: "Folio::User", user_id: user.id)
        end
      end
      puts("Accounts merged; droping table folio_accounts")
      drop_table :folio_accounts
      puts("Table folio_accounts dropped")
    end
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

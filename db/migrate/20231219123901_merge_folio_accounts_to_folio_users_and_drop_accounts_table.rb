# frozen_string_literal: true

class MergeFolioAccountsToFolioUsersAndDropAccountsTable < ActiveRecord::Migration[7.0]
  def up
    sites = connection.select_all("SELECT * FROM folio_sites").to_a

    accounts = connection.select_all("SELECT * FROM folio_accounts")

    accounts.each do |account|
      roles_to_pass = json_array(account["roles"])
      superadmin = roles_to_pass.delete("superuser").present?

      user = user_by_email(account["email"])

      if user.blank?
        puts("Creating user for account #{account["email"]}")
        except_attributes = %w[id roles is_active]
        new_attrs = account.except(*except_attributes)
        new_attrs["encrypted_password"] = account["encrypted_password"]
        new_attrs["superadmin"] = superadmin
        new_attrs["confirmed_at"] = Time.current

        # `Folio::User.create!(new_attrs)` used to interfere with db:schema:dump after migrate; use SQL insert instead.
        user_id = insert_user(new_attrs)
      else
        puts("User with email #{account["email"]} already exists")
        user_id = user["id"]
        update_user_superadmin(user_id, superadmin)
      end

      sites.each do |site|
        available_user_roles = json_array(site["available_user_roles"])
        missing_site_roles = roles_to_pass - available_user_roles

        update_site_roles(site["id"], available_user_roles + missing_site_roles) if missing_site_roles.present?
        upsert_site_user_link(user_id, site["id"], roles_to_pass)
      end

      update_console_notes(account["id"], user_id)
      update_audits(account["id"], user_id)
    end

    puts("Accounts merged; droping table folio_accounts")
    drop_table :folio_accounts
    puts("Table folio_accounts dropped")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private
    def user_by_email(email)
      connection.select_one("SELECT * FROM folio_users WHERE email = #{connection.quote(email)} LIMIT 1")
    end

    def insert_user(attributes)
      insert_sql = "INSERT INTO folio_users (#{attributes.keys.join(", ")}) " \
                   "VALUES (#{attributes.values.map { |value| connection.quote(value) }.join(", ")}) " \
                   "RETURNING id"

      connection.execute(insert_sql).first["id"]
    end

    def update_user_superadmin(user_id, superadmin)
      connection.update("UPDATE folio_users " \
                        "SET superadmin = #{connection.quote(superadmin)} " \
                        "WHERE id = #{connection.quote(user_id)}")
    end

    def update_site_roles(site_id, roles)
      connection.update("UPDATE folio_sites " \
                        "SET available_user_roles = #{connection.quote(roles.to_json)} " \
                        "WHERE id = #{connection.quote(site_id)}")
    end

    def upsert_site_user_link(user_id, site_id, roles)
      existing_link = site_user_link(user_id, site_id)

      if existing_link
        update_site_user_link(existing_link["id"], roles)
      else
        insert_site_user_link(user_id, site_id, roles)
      end
    end

    def site_user_link(user_id, site_id)
      connection.select_one("SELECT id FROM folio_site_user_links " \
                            "WHERE user_id = #{connection.quote(user_id)} " \
                            "AND site_id = #{connection.quote(site_id)} " \
                            "LIMIT 1")
    end

    def update_site_user_link(link_id, roles)
      connection.update("UPDATE folio_site_user_links " \
                        "SET roles = #{connection.quote(roles.to_json)}, updated_at = #{connection.quote(Time.current)} " \
                        "WHERE id = #{connection.quote(link_id)}")
    end

    def insert_site_user_link(user_id, site_id, roles)
      quoted_values = [
        connection.quote(user_id),
        connection.quote(site_id),
        connection.quote(roles.to_json),
        connection.quote(Time.current),
        connection.quote(Time.current),
      ]

      connection.insert("INSERT INTO folio_site_user_links (user_id, site_id, roles, created_at, updated_at) " \
                        "VALUES (#{quoted_values.join(", ")})")
    end

    def update_console_notes(account_id, user_id)
      connection.update("UPDATE folio_console_notes " \
                        "SET created_by_id = #{connection.quote(user_id)} " \
                        "WHERE created_by_id = #{connection.quote(account_id)}")
      connection.update("UPDATE folio_console_notes " \
                        "SET closed_by_id = #{connection.quote(user_id)} " \
                        "WHERE closed_by_id = #{connection.quote(account_id)}")
    end

    def update_audits(account_id, user_id)
      return unless connection.table_exists?(:audits)

      connection.update("UPDATE audits " \
                        "SET user_type = 'Folio::User', user_id = #{connection.quote(user_id)} " \
                        "WHERE user_type = 'Folio::Account' AND user_id = #{connection.quote(account_id)}")
    end

    def json_array(value)
      case value
      when Array
        value
      when String
        JSON.parse(value)
      else
        []
      end
    end
end

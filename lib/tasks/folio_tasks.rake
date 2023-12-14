# frozen_string_literal: true

namespace :folio do
  task seed_test_account: :environment do
    if Rails.env.development?
      if Folio::Account.find_by(email: "test@test.test")
        puts "Account test@test.test already exists."
      else
        Folio::Account.create!(email: "test@test.test",
                               password: "test@test.test",
                               roles: %w[superuser],
                               first_name: "Test",
                               last_name: "Dummy")
        puts "Created test@test.test account."
      end
    end
  end

  task :prepare_dummy_app do
    gem_root = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))

    from_folder = File.join(gem_root, "lib", "templates", "vendor", "assets", "redactor")
    to_folder = File.join(Dir.getwd, "test", "dummy", "vendor", "assets")

    FileUtils.mkdir_p to_folder
    FileUtils.cp_r(from_folder, to_folder)
  end

  desc "Create/Merge Folio::Acount records to Folio::User records (with correct roles)"
  task idp_merge_accounts_to_users: :environment  do
    sites = Folio::Site.all.to_a

    Folio::Account.find_each do |account|
      roles_to_pass = account.roles
      superadmin = roles_to_pass.delete("superuser").present?

      user = Folio::User.find_by(email: account.email)

      if user.blank?
        except_attributes = %w[id roles is_active]
        new_attrs = account.attributes.except(*except_attributes)
        new_attrs[:password] = Devise.friendly_token.first(8)
        new_attrs[:superadmin] = superadmin
        user = Folio::User.create!(new_attrs)
        user.reload
        user.update(encrypted_password: account.encrypted_password)
      end


      sites.each do |site|
        user.set_roles_for(site:, roles: roles_to_pass)
        raise "errors on user ##{user.id}[#{user.email}; #{account.roles}; #{site.domain}]: #{user.errors.full_messages}" unless user.save
      end
    end
  end
end

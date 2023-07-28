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
end

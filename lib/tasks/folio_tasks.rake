# frozen_string_literal: true

namespace :folio do
  task seed_test_account: :environment do
    if Rails.env.development?
      if user = Folio::User.find_by(email: "test@test.test")
        user.update!(confirmed_at: Time.current) unless user.confirmed_at?
        user.update!(superadmin: true) unless user.superadmin?

        puts "Account test@test.test already exists."
      else
        Folio::User.create!(email: "test@test.test",
                            password: "test@test.test",
                            superadmin: true,
                            first_name: "Test",
                            last_name: "Dummy",
                            confirmed_at: Time.current,
                            auth_site: Folio::Current.main_site)

        puts "Created test@test.test account."
      end
    end
  end

  task :prepare_dummy_app do
    setup_redactor
    setup_env
  end

  desc "Setup Redactor assets"
  def setup_redactor
    gem_root = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))

    from_folder = File.join(gem_root, "lib", "templates", "vendor", "assets", "redactor")
    to_folder = File.join(Dir.getwd, "test", "dummy", "vendor", "assets")
    puts "Copying Redactor assets from #{from_folder} to #{to_folder} ..."

    FileUtils.mkdir_p to_folder
    FileUtils.cp_r(from_folder, to_folder)
  end

  desc "Setup .env from .env.sample"
  def setup_env
    sample_env = File.join(Dir.getwd, "test", "dummy", ".env.sample")
    target_env = File.join(Dir.getwd, "test", "dummy", ".env")
    puts "Setting up #{target_env} from #{sample_env} ..."

    if File.exist?(sample_env)
      if File.exist?(target_env)
        puts "#{target_env} already exists, skipping."
      else
        FileUtils.cp(sample_env, target_env)
        puts "#{target_env} was copied from #{sample_env}."
      end
    else
      puts "Source #{sample_env} not found :-("
    end
  end
end

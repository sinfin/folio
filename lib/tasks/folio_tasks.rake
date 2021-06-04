# frozen_string_literal: true

namespace :folio do
  task seed_test_account: :environment do
    if Rails.env.development?
      if Folio::Account.find_by(email: "test@test.test")
        puts "Account test@test.test already exists."
      else
        Folio::Account.create!(email: "test@test.test",
                               password: "test@test.test",
                               role: :superuser,
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

  namespace :upgrade do
    task atom_document_placements: :environment do
      ids = []

      Folio::Atom.types.each do |type|
        if type::STRUCTURE[:document] && !type::STRUCTURE[:documents]
          type.includes(:document_placements).each do |atom|
            ids << atom.document_placements.pluck(:id)
          end
        end
      end

      Folio::FilePlacement::Document.where(id: ids)
                                    .update_all(type: "Folio::FilePlacement::SingleDocument")
    end

    task reset_file_file_placements_size: :environment do |t|
      Rails.logger.silence do
        Folio::File.where(file_placements_size: nil).find_each do |file|
          file.update_file_placements_size!
          print(".")
        end
      end
    end
  end
end

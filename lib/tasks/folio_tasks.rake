# frozen_string_literal: true

namespace :folio do
  task seed_test_account: :environment do
    if Rails.env.development?
      if Folio::Account.find_by(email: 'test@test.test')
        puts "Account test@test.test already exists."
      else
        Folio::Account.create!(email: 'test@test.test',
                               password: 'test@test.test',
                               role: :superuser,
                               first_name: 'Test',
                               last_name: 'Dummy')
        puts "Created test@test.test account."
      end
    end
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
                                    .update_all(type: 'Folio::FilePlacement::SingleDocument')
    end

    task reset_file_file_placements_size: :environment do |t|
      Rails.logger.silence do
        Folio::File.where(file_placements_size: nil).find_each do |file|
          file.update_file_placements_size!
          print('.')
        end
      end
    end
  end
end

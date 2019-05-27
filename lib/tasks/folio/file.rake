# frozen_string_literal: true

namespace :folio do
  namespace :file do
    task fill_missing_metadata: :environment do
      Folio::File.where(file_metadata: nil).find_each do |file_model|
        metadata = Dragonfly.app.fetch(file_model.file_uid).metadata
        file_model.update_column(:file_metadata, metadata)
      end
    end
  end
end

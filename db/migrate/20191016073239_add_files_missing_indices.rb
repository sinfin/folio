# frozen_string_literal: true

class AddFilesMissingIndices < ActiveRecord::Migration[5.2]
  def change
    add_index :folio_files, :created_at
    add_index :folio_files, :file_name
    add_index :folio_files, :hash_id

    add_index :folio_file_placements, :placement_title
    add_index :folio_file_placements, :placement_title_type

    I18n.with_locale(Rails.application.config.folio_console_locale) do
      Folio::FilePlacement::Base.find_each do |fp|
        title = fp.placement_title
        type = fp.placement_title_type
        if title.present? && type.present?
          type_name = type.safe_constantize.try(:model_name).try(:human) || type
          fp.update_column(:placement_title, "#{type_name} - #{title}")
        end
      end
    end
  end
end

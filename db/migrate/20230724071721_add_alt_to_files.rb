# frozen_string_literal: true

class AddAltToFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_files, :alt, :string

    unless reverting?
      Folio::FilePlacement::Base.where.not(alt: nil).find_each do |fp|
        if fp.file.alt.nil?
          fp.file.update_column(:alt, fp.alt)
        end
      end
    end
  end
end

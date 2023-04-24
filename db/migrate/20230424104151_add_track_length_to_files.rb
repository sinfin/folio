# frozen_string_literal: true

class AddTrackLengthToFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_files, :file_track_duration, :integer
  end
end

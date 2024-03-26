# frozen_string_literal: true

class AddPreviewTrackDurationToFolioFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :folio_files, :preview_track_duration_in_seconds, :integer
  end
end

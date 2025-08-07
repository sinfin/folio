# frozen_string_literal: true

class CreateFolioVideoSubtitles < ActiveRecord::Migration[7.1]
  def change
    create_table :folio_video_subtitles do |t|
      t.references :video, null: false, foreign_key: { to_table: :folio_files }
      t.string :language, null: false
      t.string :format, default: "vtt"
      t.text :text
      t.boolean :enabled, default: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :folio_video_subtitles, [:video_id, :language], unique: true
    add_index :folio_video_subtitles, :language
    add_index :folio_video_subtitles, :enabled
    add_index :folio_video_subtitles, :metadata, using: :gin
  end
end

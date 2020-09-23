# frozen_string_literal: true

class CreateFolioSessionAttachments < ActiveRecord::Migration[6.0]
  def change
    create_table :folio_session_attachments do |t|
      t.string :hash_id, index: true

      t.string :file_uid
      t.string :file_name
      t.bigint :file_size
      t.string :file_mime_type

      t.string :type, index: true

      t.string :web_session_id, index: true
      t.jsonb :thumbnail_sizes, default: {}

      t.belongs_to :visit
      t.belongs_to :placement, polymorphic: true, index: {
        name: :index_folio_session_attachments_on_placement
      }

      t.timestamps
    end
  end
end

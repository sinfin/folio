# frozen_string_literal: true

class AddFileProcessingAttributesToFolioFiles < ActiveRecord::Migration[8.0]
  def up
    enable_extension "uuid-ossp"

    %i[folio_files folio_private_attachments folio_session_attachments].each do |table_name|
      change_table(table_name) do |t|
        # Unique file identifier -> this should be used are primary key instead of bigint id (will be probably changed in
        # future)
        t.uuid :file_uuid, null: false, default: "uuid_generate_v4()"

        # Base path to original file. In this path (directory) will be stored versions, thumbnails (if we want to store
        # them) and other files related to original
        t.string :s3_base_path

        t.integer :version, null: false, default: 0

        # Used for session files
        t.string :reference_key

        t.jsonb :metadata, null: false, default: {}

        t.jsonb :metadata_rekognition, null: false, default: {}

        # Used for user private session file
        t.belongs_to :user, null: true, foreign_key: { to_table: :folio_users }
      end

      add_index table_name, :file_uuid, unique: true
      add_index table_name, :reference_key, where: "reference_key IS NOT NULL"
    end

    %i[folio_private_attachments folio_session_attachments].each do |table_name|
      change_table(table_name) do |t|
        t.string :aasm_state, null: false, default: "new"
      end

      execute("UPDATE #{table_name} SET aasm_state = 'ready'")
    end
  end

  def down
    %i[folio_files folio_private_attachments folio_session_attachments].each do |table_name|
      change_table(table_name) do |t|
        t.remove :file_uuid
        t.remove :s3_base_path
        t.remove :version
        t.remove :reference_key
        t.remove :metadata
        t.remove :metadata_rekognition
        t.remove_references :user
      end
    end

    %i[folio_private_attachments folio_session_attachments].each do |table_name|
      change_table(table_name) do |t|
        t.remove :aasm_state
      end
    end
  end
end

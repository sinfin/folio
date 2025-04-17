# frozen_string_literal: true

class AddFileProcessingAttributesToFolioFiles < ActiveRecord::Migration[8.0]
  def up
    enable_extension "uuid-ossp"

    %i[folio_files folio_private_attachments folio_session_attachments].each do |table_name|
      change_table(table_name) do |t|
        # Unique file identifier -> this should be used are primary key instead of bigint id (will be probably changed in
        # future)
        t.uuid :file_uuid, null: false, default: "uuid_generate_v4()"

        # Path to S3 where file is located
        t.string :s3_path

        # Used for session
        t.string :reference_key

        # Basic metadata obtained by lambda
        t.jsonb :metadata, null: false, default: {}

        # Metadata from rekognition lambda
        t.jsonb :metadata_rekognition, null: false, default: {}

        t.references :user
      end

      add_index table_name, :file_uuid, unique: true
      add_index table_name, :reference_key, where: "reference_key IS NOT NULL"
    end

    %i[folio_private_attachments folio_session_attachments].each do |table_name|
      change_table(table_name) do |t|
        t.string :aasm_state, null: false, default: "initialized"
      end

      execute("UPDATE #{table_name} SET aasm_state = 'ready'")
    end
  end

  def down
    %i[folio_files folio_private_attachments folio_session_attachments].each do |table_name|
      change_table(table_name) do |t|
        t.remove :file_uuid
        t.remove :s3_path
        t.remove :reference_key
        t.remove :metadata
        t.remove :metadata_rekognition
      end
    end

    %i[folio_private_attachments folio_session_attachments].each do |table_name|
      change_table(table_name) do |t|
        t.remove :aasm_state
      end
    end
  end
end

# frozen_string_literal: true

# :nodoc:
class CreateAwsFileHandlerFiles < ActiveRecord::Migration[8.0]
  def change
    enable_extension "uuid-ossp"

    create_table :aws_file_handler_files, id: :uuid do |t|
      # File name
      t.string :name, null: false

      # Mime type from AWS
      t.string :mime_type, null: true

      # State in AWS
      t.string :aasm_state, null: false, default: "initialized"

      # Custom data from your app
      t.jsonb :custom_data, null: false, default: {}

      # S3 path part. It's used for better sorting in S3. You want to use, for example,
      # Folio::PrivateAttachment::Image.underscore. It creates s3_path
      # "uploads/#{Time.now.strftime("%Y/%m/%d")}/#{s3_type_directory}/#{file_uuid}" which will create something like
      # "uploads/2025/06/18/folio/private_attachment/image/32375321-5da1-48c0-9dc9-ed1a4d4d7df8/file"
      t.string :s3_type_directory, null: false

      # Path to S3 where file is located
      t.string :s3_path

      # Used for session
      t.string :reference_key

      # Basic metadata obtained by lambda
      t.jsonb :metadata, null: false, default: {}

      # Metadata from rekognition lambda
      t.jsonb :metadata_rekognition, null: false, default: {}

      # Optional reference to User
      t.references :user, type: :bigint, null: true
      t.references :typeable, type: :bigint, polymorphic: true, null: true

      t.timestamps
    end

    add_index :aws_file_handler_files, :reference_key, where: "reference_key IS NOT NULL"
  end
end

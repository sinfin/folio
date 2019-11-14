# frozen_string_literal: true

class CreateFolioPrivateAttachments < ActiveRecord::Migration[5.2]
  def change
    create_table :folio_private_attachments do |t|
      t.belongs_to :attachmentable, polymorphic: true,
                                    index: { name: :index_folio_private_attachments_on_attachmentable }

      t.string :type, index: true

      t.string :file_uid
      t.string :file_name

      t.text :title
      t.string :alt

      t.text :thumbnail_sizes

      t.integer :position

      t.integer :file_width
      t.integer :file_height
      t.bigint :file_size
      t.string :mime_type, limit: 255

      t.json :additional_data

      t.timestamps
    end
  end
end

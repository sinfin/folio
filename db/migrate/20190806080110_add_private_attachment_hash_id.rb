# frozen_string_literal: true

class AddPrivateAttachmentHashId < ActiveRecord::Migration[5.2]
  def change
    add_column :folio_private_attachments, :hash_id, :string, index: true

    Folio::PrivateAttachment.find_each do |file|
      file.set_hash_id
      file.update_column(:hash_id, file.hash_id)
    end
  end
end

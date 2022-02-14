class RmPrivateAttachmentsMimeTypeColumn < ActiveRecord::Migration[6.1]
  def change
    remove_column :folio_private_attachments, :mime_type, :string
  end
end

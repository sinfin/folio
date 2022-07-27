# frozen_string_literal: true

class UseFileMimeTypeForPrivateAttachments < ActiveRecord::Migration[6.1]
  def change
    add_column :folio_private_attachments, :file_mime_type, :string

    unless reverting?
      execute "UPDATE folio_private_attachments SET file_mime_type = mime_type;"
    end
  end
end

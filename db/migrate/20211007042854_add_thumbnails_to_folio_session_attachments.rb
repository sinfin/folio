# frozen_string_literal: true

class AddThumbnailsToFolioSessionAttachments < ActiveRecord::Migration[6.1]
  def change
    add_column :folio_session_attachments, :thumbnail_sizes, :json, default: {}
  end
end

# frozen_string_literal: true

class RmSessionAttachmentThumbnails < ActiveRecord::Migration[6.0]
  def change
    remove_column :folio_session_attachments, :thumbnail_sizes, :json, default: {}
    add_column :folio_session_attachments, :file_width, :integer
    add_column :folio_session_attachments, :file_height, :integer
  end
end

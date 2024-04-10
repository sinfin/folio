# frozen_string_literal: true

class AddFolioPrivateAttachmentsThumbnailSizesDefault < ActiveRecord::Migration[7.1]
  def change
    change_column_default :folio_private_attachments, :thumbnail_sizes, from: nil, to: "--- {}\n"
  end
end

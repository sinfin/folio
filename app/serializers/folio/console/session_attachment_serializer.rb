# frozen_string_literal: true

class Folio::Console::SessionAttachmentSerializer
  include FastJsonapi::ObjectSerializer

  # Session attachments are addressed by hash_id (FriendlyId), never by the
  # numeric primary key.
  set_id :hash_id

  attributes :file_name,
             :file_size,
             :file_mime_type,
             :type

  # Dropzone reads attributes.id to build the destroy url, and
  # Folio::SessionAttachmentsController#destroy looks records up by hash_id.
  attribute :id do |object|
    object.hash_id
  end
end

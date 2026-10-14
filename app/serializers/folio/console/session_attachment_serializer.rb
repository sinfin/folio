# frozen_string_literal: true

class Folio::Console::SessionAttachmentSerializer
  include FastJsonapi::ObjectSerializer

  attributes :file_name,
             :file_size,
             :file_mime_type,
             :type

  # Dropzone uses this id to build the destroy url, and
  # Folio::SessionAttachmentsController#destroy looks records up by hash_id.
  attribute :id do |object|
    object.hash_id
  end
end

# frozen_string_literal: true

class Folio::Console::PrivateAttachmentSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :file_size,
             :file_name,
             :type,
             :title

  attribute :expiring_url do |object|
    object.file.remote_url(expires_in: 1.hour.from_now)
  end
end

# frozen_string_literal: true

class Folio::Console::PrivateAttachmentSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :file_size,
             :file_name,
             :type,
             :title

  attribute :expiring_url do |object|
    Folio::S3.url_rewrite(object.file.remote_url(expires: 1.hour.from_now))
  end
end

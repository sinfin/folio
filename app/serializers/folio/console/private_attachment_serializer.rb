# frozen_string_literal: true

class Folio::Console::PrivateAttachmentSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id,
             :file_size,
             :file_name,
             :type,
             :title

  # Use a stable download path instead of an expiring presigned URL.
  # The DownloadsController generates a fresh presigned URL on-the-fly.
  # This is cacheable and doesn't expose time-limited URLs in JSON responses.
  attribute :download_url do |object|
    # Build the path directly since FastJsonapi doesn't have access to route helpers
    "/download/#{object.hash_id}"
  end
end

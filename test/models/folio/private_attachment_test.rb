# frozen_string_literal: true

require "test_helper"

module Folio
  class PrivateAttachmentTest < ActiveSupport::TestCase
    test "serializer returns download_url instead of expiring_url" do
      private_attachment = create(:folio_private_attachment)

      serializer = Folio::Console::PrivateAttachmentSerializer.new(private_attachment)
      serialized = serializer.serializable_hash[:data][:attributes]

      # Should have download_url (stable path)
      assert serialized.key?(:download_url), "Expected serializer to include :download_url"
      assert_equal "/download/#{private_attachment.hash_id}", serialized[:download_url]

      # Should NOT have expiring_url (removed to avoid caching issues)
      assert_not serialized.key?(:expiring_url), "Expected serializer NOT to include :expiring_url"
    end

    test "download_url is a stable path not a presigned URL" do
      private_attachment = create(:folio_private_attachment)

      serializer = Folio::Console::PrivateAttachmentSerializer.new(private_attachment)
      download_url = serializer.serializable_hash[:data][:attributes][:download_url]

      # The URL should be a path (starts with /) not a full S3 URL
      assert download_url.start_with?("/"), "Expected download_url to be a path, got: #{download_url}"
      # Should NOT contain S3/AWS authentication parameters
      assert_not download_url.include?("X-Amz"), "Expected download_url NOT to be a presigned URL"
      assert_not download_url.include?("amazonaws.com"), "Expected download_url NOT to be an S3 URL"
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class Folio::Console::SessionAttachmentSerializerTest < ActiveSupport::TestCase
  test "exposes hash_id as attributes id so the dropzone can destroy the record" do
    attachment = create(:folio_session_attachment_image)

    data = Folio::Console::SessionAttachmentSerializer.new(attachment).serializable_hash[:data]

    assert_equal attachment.hash_id, data[:attributes][:id]
    assert_equal attachment.file_name, data[:attributes][:file_name]
    assert_equal attachment.file_size, data[:attributes][:file_size]
    assert_equal attachment.file_mime_type, data[:attributes][:file_mime_type]
    assert_equal attachment.type, data[:attributes][:type]
  end
end

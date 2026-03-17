# frozen_string_literal: true

require "test_helper"

class Folio::CraMediaCloud::EncoderTest < ActiveSupport::TestCase
  test "build_ingest_manifest uses src attribute with presigned URL" do
    encoder = Folio::CraMediaCloud::Encoder.new

    file_mock = Struct.new(:file_name, :file_size, :file_uid, :id).new(
      "video.mp4", 123456, "uploads/video.mp4", 1
    )

    presigned_url = "https://s3.amazonaws.com/bucket/uploads/video.mp4?X-Amz-Credential=xxx&X-Amz-Expires=604800"

    manifest_xml = encoder.send(
      :build_ingest_manifest,
      file_mock,
      md5: "abc123def456",
      ref_id: "test-ref-001",
      profile_group: "VoDSD",
      presigned_url: presigned_url
    )

    assert_includes manifest_xml, 'src="https://s3.amazonaws.com/bucket/uploads/video.mp4'
    assert_not_includes manifest_xml, 'file='
    assert_includes manifest_xml, 'size="123456"'
    assert_includes manifest_xml, 'md5="abc123def456"'
    assert_includes manifest_xml, "<profileGroup>VoDSD</profileGroup>"
    assert_includes manifest_xml, "<refId>test-ref-001</refId>"
  end

  test "build_ingest_manifest falls back to file attribute when no presigned URL" do
    encoder = Folio::CraMediaCloud::Encoder.new

    file_mock = Struct.new(:file_name, :file_size, :file_uid, :id).new(
      "video.mp4", 123456, "uploads/video.mp4", 1
    )

    manifest_xml = encoder.send(
      :build_ingest_manifest,
      file_mock,
      md5: "abc123def456",
      ref_id: "test-ref-001",
      profile_group: "VoD",
      presigned_url: nil
    )

    assert_includes manifest_xml, 'file="video.mp4"'
    assert_not_includes manifest_xml, 'src='
  end
end

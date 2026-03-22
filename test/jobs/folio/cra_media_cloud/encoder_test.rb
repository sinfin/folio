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
    assert_not_includes manifest_xml, "file="
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
    assert_not_includes manifest_xml, "src="
  end

  # --- upload_file ---

  test "upload_file builds manifest and uploads it via SFTP, returns result hash" do
    encoder = Folio::CraMediaCloud::Encoder.new

    file_mock = Struct.new(:file_name, :file_size, :file_uid, :id, :slug).new(
      "video.mp4", 123456, "uploads/video.mp4", 42, "my-video"
    )

    s3_metadata_mock = Struct.new(:headers).new({ "ETag" => '"abcd1234"' })
    fake_presigned_url = "https://s3.amazonaws.com/bucket/video.mp4?X-Amz-Expires=604800"

    uploaded_path = nil
    uploaded_xml  = nil
    fake_sftp = Object.new
    fake_sftp.define_singleton_method(:upload!) do |source, dest|
      uploaded_path = dest
      uploaded_xml  = source.read
    end

    encoder.define_singleton_method(:with_robust_sftp_session) { |&blk| blk.call(fake_sftp) }

    result = encoder.stub(:s3_dragonfly_head_object, s3_metadata_mock) do
      encoder.stub(:generate_presigned_url, fake_presigned_url) do
        encoder.upload_file(file_mock, reference_id: "test-ref-001")
      end
    end

    assert_equal "test-ref-001", result[:ref_id]
    assert_equal "/ingest/regular/test-ref-001_manifest.xml", result[:xml_manifest_path]
    assert result[:presigned_url], "presigned_url flag should be truthy"
    assert_equal "/ingest/regular/test-ref-001_manifest.xml", uploaded_path
    assert_includes uploaded_xml, "<refId>test-ref-001</refId>"
    assert_includes uploaded_xml, fake_presigned_url
  end

  test "upload_file uses provided reference_id in SFTP path" do
    encoder = Folio::CraMediaCloud::Encoder.new

    file_mock = Struct.new(:file_name, :file_size, :file_uid, :id, :slug).new(
      "video.mp4", 100, "uploads/video.mp4", 1, "slug"
    )

    s3_metadata_mock = Struct.new(:headers).new({ "ETag" => '"ff00ff00"' })
    uploaded_path = nil
    fake_sftp = Object.new
    fake_sftp.define_singleton_method(:upload!) { |_src, dest| uploaded_path = dest }

    encoder.define_singleton_method(:with_robust_sftp_session) { |&blk| blk.call(fake_sftp) }

    encoder.stub(:s3_dragonfly_head_object, s3_metadata_mock) do
      encoder.stub(:generate_presigned_url, "https://s3.example.com/v.mp4") do
        encoder.upload_file(file_mock, reference_id: "custom-ref-xyz")
      end
    end

    assert_equal "/ingest/regular/custom-ref-xyz_manifest.xml", uploaded_path
  end

  # --- upload_with_retry ---

  test "upload_with_retry raises immediately when max_retries is 0" do
    encoder = Folio::CraMediaCloud::Encoder.new

    failing_sftp = Object.new
    failing_sftp.define_singleton_method(:upload!) { |_, _| raise "network error" }

    err = assert_raises(RuntimeError) do
      encoder.send(:upload_with_retry, failing_sftp, StringIO.new("data"), "/dest/manifest.xml", max_retries: 0)
    end
    assert_match "network error", err.message
  end

  test "upload_with_retry retries on transient failure and succeeds on next attempt" do
    encoder = Folio::CraMediaCloud::Encoder.new
    encoder.define_singleton_method(:sleep) { |_| }  # no-op to avoid real sleep in tests

    attempts = 0
    flaky_sftp = Object.new
    flaky_sftp.define_singleton_method(:upload!) do |_src, _dest|
      attempts += 1
      raise "transient error" if attempts < 2
    end

    encoder.send(:upload_with_retry, flaky_sftp, StringIO.new("data"), "/dest/manifest.xml", max_retries: 1)

    assert_equal 2, attempts
  end

  test "upload_with_retry raises after all retries exhausted" do
    encoder = Folio::CraMediaCloud::Encoder.new
    encoder.define_singleton_method(:sleep) { |_| }

    attempts = 0
    always_fail_sftp = Object.new
    always_fail_sftp.define_singleton_method(:upload!) do |_, _|
      attempts += 1
      raise "persistent error"
    end

    assert_raises(RuntimeError, /persistent error/) do
      encoder.send(:upload_with_retry, always_fail_sftp, StringIO.new("data"), "/dest/manifest.xml", max_retries: 2)
    end

    assert_equal 3, attempts  # 1 initial + 2 retries
  end

  # --- with_robust_sftp_session ---

  test "with_robust_sftp_session wraps SSH authentication failure" do
    encoder = Folio::CraMediaCloud::Encoder.new

    # ENV vars must be present so Net::SSH.start is actually reached (before the stub fires)
    ENV["CRA_MEDIA_CLOUD_SFTP_HOST"]     = "sftp.example.com"
    ENV["CRA_MEDIA_CLOUD_SFTP_USERNAME"] = "user"
    ENV["CRA_MEDIA_CLOUD_SFTP_PASSWORD"] = "pass"

    Net::SSH.stub(:start, ->(*_args, **_kwargs) { raise Net::SSH::AuthenticationFailed, "bad credentials" }) do
      err = assert_raises(RuntimeError) do
        encoder.send(:with_robust_sftp_session) { |_sftp| }
      end
      assert_match "SSH authentication failed", err.message
    end
  ensure
    %w[CRA_MEDIA_CLOUD_SFTP_HOST CRA_MEDIA_CLOUD_SFTP_USERNAME CRA_MEDIA_CLOUD_SFTP_PASSWORD].each { |k| ENV.delete(k) }
  end

  test "with_robust_sftp_session wraps generic SFTP errors" do
    encoder = Folio::CraMediaCloud::Encoder.new

    ENV["CRA_MEDIA_CLOUD_SFTP_HOST"]     = "sftp.example.com"
    ENV["CRA_MEDIA_CLOUD_SFTP_USERNAME"] = "user"
    ENV["CRA_MEDIA_CLOUD_SFTP_PASSWORD"] = "pass"

    Net::SSH.stub(:start, ->(*_args, **_kwargs) { raise "connection refused" }) do
      err = assert_raises(RuntimeError) do
        encoder.send(:with_robust_sftp_session) { |_sftp| }
      end
      assert_match "SFTP session error", err.message
    end
  ensure
    %w[CRA_MEDIA_CLOUD_SFTP_HOST CRA_MEDIA_CLOUD_SFTP_USERNAME CRA_MEDIA_CLOUD_SFTP_PASSWORD].each { |k| ENV.delete(k) }
  end
end

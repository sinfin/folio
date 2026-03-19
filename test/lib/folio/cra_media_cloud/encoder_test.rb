# frozen_string_literal: true

require "test_helper"

class Folio::CraMediaCloud::EncoderTest < ActiveSupport::TestCase
  setup do
    @encoder = Folio::CraMediaCloud::Encoder.new
    @file = OpenStruct.new(
      id: 42,
      file_name: "test_video.mp4",
      file_size: "123456",
    )
    @defaults = { md5: "abc123", ref_id: "42-1234567890", profile_group: "VoD" }
  end

  test "build_ingest_manifest includes processingPhases attribute when processing_phases is 2" do
    xml = @encoder.send(:build_ingest_manifest, @file, **@defaults, processing_phases: 2)

    assert_includes xml, 'processingPhases="2"'
    assert_includes xml, "<vod_encoder_job"
  end

  test "build_ingest_manifest does not include processingPhases when processing_phases is 1" do
    xml = @encoder.send(:build_ingest_manifest, @file, **@defaults, processing_phases: 1)

    assert_not_includes xml, "processingPhases"
  end

  test "build_ingest_manifest does not include processingPhases when processing_phases is nil" do
    xml = @encoder.send(:build_ingest_manifest, @file, **@defaults, processing_phases: nil)

    assert_not_includes xml, "processingPhases"
  end

  test "build_ingest_manifest is backward compatible when processing_phases is not passed" do
    xml_without = @encoder.send(:build_ingest_manifest, @file, **@defaults)
    xml_with_nil = @encoder.send(:build_ingest_manifest, @file, **@defaults, processing_phases: nil)

    assert_equal xml_without, xml_with_nil
    assert_not_includes xml_without, "processingPhases"
  end
end

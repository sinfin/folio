# frozen_string_literal: true

require "test_helper"

class Folio::UppyComponentTest < Folio::ComponentTest
  def test_render
    file_type = "Folio::File::Image"

    render_inline(Folio::UppyComponent.new(file_type:)) { "Upload" }

    assert_selector(".f-uppy")
  end

  def test_render_keeps_multipart_upload_disabled_by_default
    original = Rails.application.config.folio_direct_s3_multipart_upload_enabled
    Rails.application.config.folio_direct_s3_multipart_upload_enabled = false

    render_inline(Folio::UppyComponent.new(file_type: "Folio::File::Image")) { "Upload" }

    assert_selector(".f-uppy[data-f-uppy-multipart-upload-enabled-value='false']")
  ensure
    Rails.application.config.folio_direct_s3_multipart_upload_enabled = original
  end

  def test_render_exposes_multipart_upload_config_when_enabled
    original_enabled = Rails.application.config.folio_direct_s3_multipart_upload_enabled
    original_min_file_size = Rails.application.config.folio_direct_s3_multipart_upload_min_file_size
    Rails.application.config.folio_direct_s3_multipart_upload_enabled = true
    Rails.application.config.folio_direct_s3_multipart_upload_min_file_size = 42

    render_inline(Folio::UppyComponent.new(file_type: "Folio::File::Image")) { "Upload" }

    assert_selector(".f-uppy[data-f-uppy-multipart-upload-enabled-value='true']")
    assert_selector(".f-uppy[data-f-uppy-multipart-upload-min-file-size-value='42']")
  ensure
    Rails.application.config.folio_direct_s3_multipart_upload_enabled = original_enabled
    Rails.application.config.folio_direct_s3_multipart_upload_min_file_size = original_min_file_size
  end

  def test_render_uses_configured_direct_s3_upload_max_file_size_by_default
    original_max_file_size = Rails.application.config.folio_direct_s3_upload_max_file_size
    Rails.application.config.folio_direct_s3_upload_max_file_size = 80.gigabytes

    render_inline(Folio::UppyComponent.new(file_type: "Folio::File::Image")) { "Upload" }

    assert_selector(".f-uppy[data-f-uppy-max-file-size-value='85899345920']")
  ensure
    Rails.application.config.folio_direct_s3_upload_max_file_size = original_max_file_size
  end
end

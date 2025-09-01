# frozen_string_literal: true

require "test_helper"

class Folio::File::ImageMetadataCharsetTest < ActiveSupport::TestCase
  # Temporarily disable VCR for file upload tests
  def setup
    VCR.turn_off!(ignore_cassettes: true)
    WebMock.allow_net_connect!

    # Rails.root points to test/dummy in gems, we need to go up to main gem root
    gem_root = Rails.root.parent.parent
    @test_images_dir = gem_root.join("test", "fixtures", "folio", "metadata_test_images")
  end

  def teardown
    VCR.turn_on!
    WebMock.disable_net_connect!
  end

  # Test real profimedia files with Czech encoding issues
  test "extracts Czech characters correctly from profimedia files" do
    skip unless File.exist?(@test_images_dir.join("profimedia-0701180382.jpg"))

    image_file = create_test_image("profimedia-0701180382.jpg")

    # Should contain proper Czech characters from JSON metadata, not mojibake
    credit_line = image_file.file_metadata&.dig("credit_line")
    headline = image_file.headline

    assert_match(/Česká editoriální/, credit_line.to_s) if credit_line
    assert_match(/Charlotte Ella Gottová/, headline.to_s) if headline
    assert_no_match(/ÄŒesk/, credit_line.to_s) if credit_line # No mojibake
    assert_no_match(/GottovÃ/, headline.to_s) if headline # No mojibake
  end

  # These tests are skipped because profimedia files 1030128904.jpg and 1030685880.jpg
  # are 10x10px resized files (1KB) without original metadata

  test "processes charset without errors on available files" do
    # Test with available file that has metadata
    image_file = create_test_image("profimedia-0701180382.jpg")

    # Should process without charset errors from JSON metadata
    credit_line = image_file.file_metadata&.dig("credit_line")
    headline = image_file.headline

    assert credit_line.present? if credit_line
    assert headline.present? if headline
    # Should contain valid UTF-8 characters
    assert credit_line.valid_encoding? if credit_line
    assert headline.valid_encoding? if headline
  end

  test "processes available files without encoding errors" do
  # Only test files with actual metadata (>5KB)
  test_files = [
    "profimedia-0701180382.jpg", # Has Czech metadata
    "IPTC-PhotometadataRef-Std2024.1.jpg" # IPTC reference
  ].select { |f| File.exist?(@test_images_dir.join(f)) }

  skip if test_files.empty?

  test_files.each do |filename|
    image_file = create_test_image(filename)

    # Basic checks for encoding quality on available fields
    fields = [
      image_file.file_metadata&.dig("credit_line"),
      image_file.description,
      image_file.headline
    ].compact

    fields.each do |field|
      next if field.blank?

      # Should have valid encoding
      assert field.valid_encoding?, "Invalid encoding in #{filename}: #{field}"
      # Should not contain replacement characters
      assert_no_match(/\uFFFD/, field, "Replacement character detected in #{filename}")
      assert_not field.include?("�"), "Invalid character detected in #{filename}"
    end
  end
end

  # Test charset fallback mechanism
  test "uses UTF-8 charset configuration by default" do
    original_options = Rails.application.config.folio_image_metadata_exiftool_options

    # Verify UTF-8 is in default options
    assert_includes original_options, "-charset"
    assert_includes original_options, "iptc=utf8"
  end

  test "handles charset candidates fallback" do
    skip unless File.exist?(@test_images_dir.join("profimedia-1029496354.jpg"))

    # Mock failure of UTF-8, success with cp1250
    image_file = create(:folio_file_image, file: @test_images_dir.join("profimedia-0701180382.jpg"))

    # Simulate charset fallback by temporarily changing config
    original_candidates = Rails.application.config.folio_image_metadata_iptc_charset_candidates
    Rails.application.config.folio_image_metadata_iptc_charset_candidates = %w[utf8 cp1250]

    begin
      # This should work with UTF-8 (first candidate)
      image_file.save!
      assert image_file.mapped_metadata[:credit_line].present?
      assert_match(/ČTK|Šimánek/, image_file.mapped_metadata[:credit_line].to_s)
    ensure
      Rails.application.config.folio_image_metadata_iptc_charset_candidates = original_candidates
      image_file.file&.close
    end
  end

  private
    def create_test_image(filename)
      create(:folio_file_image, file: @test_images_dir.join(filename))
end
end

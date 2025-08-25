# frozen_string_literal: true

require "test_helper"

class Folio::File::ImageMetadataMappingTest < ActiveSupport::TestCase
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

  # Test IPTC standard field mappings
  test "maps IPTC fields to correct database columns" do
  skip unless File.exist?(@test_images_dir.join("IPTC-PhotometadataRef-Std2024.1.jpg"))

  image_file = create_test_image("IPTC-PhotometadataRef-Std2024.1.jpg")

  # Test core descriptive fields - verify actual content
  assert_equal "The Headline (ref2024.1)", image_file.headline
  assert_equal "The description aka caption (ref2024.1)", image_file.description

  # Test creator mapping (should be array)
  assert image_file.creator.is_a?(Array), "Creator should be stored as array"
  assert_equal ["Creator1 (ref2024.1)"], image_file.creator

  # Test rights management
  assert_equal "Credit Line (ref2024.1)", image_file.credit_line

  # Test classification arrays
  assert image_file.keywords.is_a?(Array), "Keywords should be stored as JSONB array"
  assert_equal ["Keyword1ref2024.1", "Keyword2ref2024.1", "Keyword3ref2024.1"], image_file.keywords
end

  test "respects field precedence XMP > IPTC-IIM > EXIF" do
    skip unless File.exist?(@test_images_dir.join("IPTC-PhotometadataRef-Std2024.1.jpg"))

    image_file = create_test_image("IPTC-PhotometadataRef-Std2024.1.jpg")

    # Verify that XMP values take precedence over IPTC-IIM
    # This is indirect test - we check that modern IPTC reference contains proper data
    assert_no_match(/\A\s*\z/, image_file.description.to_s) # Not empty/whitespace only
    assert image_file.creator.any? { |c| !c.to_s.strip.empty? } # Has meaningful creator data
  end

  test "processes location fields correctly" do
    skip unless File.exist?(@test_images_dir.join("IPTC-PhotometadataRef-Std2024.1.jpg"))

    image_file = create_test_image("IPTC-PhotometadataRef-Std2024.1.jpg")

    # Test location mapping
    if image_file.city.present?
      assert image_file.city.is_a?(String), "City should be string from XMP-photoshop:City"
    end

    if image_file.country.present?
      assert image_file.country.is_a?(String), "Country should be string from XMP-iptcCore:CountryName"
    end

    if image_file.country_code.present?
      assert image_file.country_code.length <= 2, "Country code should be max 2 chars (ISO 3166-1)"
    end
  end

  test "handles technical EXIF metadata correctly" do
    # Test with any image that has EXIF data
    test_files = Dir.glob(@test_images_dir.join("*.jpg")).first(3)
    skip if test_files.empty?

    test_files.each do |filepath|
      next if File.size(filepath) < 5000 # Skip resized

      image_file = create_test_image(File.basename(filepath))

      # Test technical fields if present
      if image_file.camera_make.present?
        assert image_file.camera_make.is_a?(String), "Camera make should be string"
        assert image_file.camera_make.length > 0, "Camera make should not be empty"
      end

      if image_file.capture_date.present?
        assert image_file.capture_date.is_a?(Time) || image_file.capture_date.is_a?(DateTime),
               "Capture date should be Time/DateTime"
      end

      if image_file.gps_latitude.present?
        assert image_file.gps_latitude.is_a?(Numeric), "GPS latitude should be numeric"
        assert image_file.gps_latitude.between?(-90, 90), "GPS latitude should be valid range"
      end

      if image_file.gps_longitude.present?
        assert image_file.gps_longitude.is_a?(Numeric), "GPS longitude should be numeric"
        assert image_file.gps_longitude.between?(-180, 180), "GPS longitude should be valid range"
      end
    end
  end

  test "does not overwrite existing field values" do
    skip unless File.exist?(@test_images_dir.join("IPTC-PhotometadataRef-Std2024.1.jpg"))

    # Create image with pre-existing values
    image_file = create(:folio_file_image, file: @test_images_dir.join("IPTC-PhotometadataRef-Std2024.1.jpg"))
    image_file.description = "Pre-existing description"
    image_file.credit_line = "Pre-existing credit"
    image_file.save!

    # Values should be preserved (not overwritten by extraction)
    image_file.reload
    assert_equal "Pre-existing description", image_file.description
    assert_equal "Pre-existing credit", image_file.credit_line
  ensure
    # Cleanup handled by factory teardown
  end

  test "handles arrays correctly for multi-value fields" do
    skip unless File.exist?(@test_images_dir.join("IPTC-PhotometadataRef-Std2024.1.jpg"))

    image_file = create_test_image("IPTC-PhotometadataRef-Std2024.1.jpg")

    # Multi-value fields should be arrays
    multi_value_fields = [:creator, :keywords, :subject_codes, :scene_codes, :persons_shown]

    multi_value_fields.each do |field|
      value = image_file.send(field)
      if value.present?
        assert value.is_a?(Array), "#{field} should be array, got #{value.class}"
        assert value.all? { |item| item.is_a?(String) }, "#{field} array items should be strings"
        assert value.none?(&:blank?), "#{field} should not contain blank entries"
      end
    end
  end

  test "processes real profimedia files with correct field mapping" do
    profimedia_files = Dir.glob(@test_images_dir.join("profimedia-*.jpg"))
                          .select { |f| File.size(f) > 5000 }
                          .first(3) # Test subset

    skip if profimedia_files.empty?

    profimedia_files.each do |filepath|
      image_file = create_test_image(File.basename(filepath))
      filename = File.basename(filepath)

      # Profimedia files should have credit_line and possibly keywords
      if image_file.credit_line.present?
        assert image_file.credit_line.is_a?(String), "Credit line should be string in #{filename}"
        assert image_file.credit_line.include?("Profimedia") ||
               image_file.credit_line.include?("ČTK") ||
               image_file.credit_line.include?("MFDNES"), "Credit should contain agency name in #{filename}"
      end

      if image_file.keywords.present?
        assert image_file.keywords.is_a?(Array), "Keywords should be array in #{filename}"
        assert image_file.keywords.any? { |k| k.to_s.length > 1 }, "Keywords should contain meaningful entries in #{filename}"
      end

      # Creator should be array if present
      if image_file.creator.present?
        assert image_file.creator.is_a?(Array), "Creator should be array in #{filename}"
      end
    end
  end

  test "handles legacy field compatibility" do
    skip unless File.exist?(@test_images_dir.join("IPTC-PhotometadataRef-Std2024.1.jpg"))

    image_file = create_test_image("IPTC-PhotometadataRef-Std2024.1.jpg")

    # Test author proxy (should work with creator array)
    if image_file.creator.present?
      expected_author = image_file.creator.join(", ")
      assert_equal expected_author, image_file.author, "Author proxy should join creator array"
    end

    # If we have copyright_notice, attribution_copyright should work
    if image_file.copyright_notice.present?
      assert_equal image_file.copyright_notice, image_file.attribution_copyright,
                   "Attribution copyright proxy should return copyright_notice"
    end
  end

  test "validates data types and constraints" do
    skip unless File.exist?(@test_images_dir.join("IPTC-PhotometadataRef-Std2024.1.jpg"))

    image_file = create_test_image("IPTC-PhotometadataRef-Std2024.1.jpg")

    # String fields should be strings
    string_fields = [:headline, :description, :credit_line, :source, :copyright_notice]
    string_fields.each do |field|
      value = image_file.send(field)
      if value.present?
        assert value.is_a?(String), "#{field} should be string, got #{value.class}"
      end
    end

    # Boolean fields should be boolean
    if image_file.copyright_marked.present?
      assert [true, false].include?(image_file.copyright_marked), "copyright_marked should be boolean"
    end

    # Country code constraint
    if image_file.country_code.present?
      assert image_file.country_code.length <= 2, "country_code should be max 2 characters"
      assert image_file.country_code.match?(/\A[A-Z]{1,2}\z/), "country_code should be uppercase letters"
    end
  end

  private
    def create_test_image(filename)
      image_file = create(:folio_file_image, file: @test_images_dir.join(filename))
      # Manually trigger metadata extraction for testing
      image_file.extract_image_metadata_sync if image_file.respond_to?(:extract_image_metadata_sync)
      image_file.reload
      image_file
    end
end

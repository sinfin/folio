# frozen_string_literal: true

require "test_helper"

class Folio::ImageMetadataExtractionIntegrationTest < ActionDispatch::IntegrationTest
  def setup
    # Use the gem's fixtures directory, not the dummy app's
    gem_root = File.expand_path("../../..", __dir__)
    @test_images_dir = File.join(gem_root, "test", "fixtures", "folio", "metadata_test_images")

    # Ensure we have a site for testing
    @site = Folio::Site.first || Folio::Site.create!(
      title: "Test Site",
      domain: "test.example.com",
      locale: "en",
      type: "Folio::Site",
      email: "test@example.com",
      locales: ["en"]
    )
  end

  # End-to-end test: upload → ExifTool extraction → charset handling → database storage
  test "complete metadata extraction pipeline with UTF-8 charset" do
    file_path = File.join(@test_images_dir, "profimedia-0701180382.jpg")
    skip unless File.exist?(file_path)

    temp_file = nil
    image_file = nil

    begin
      # Simulate file upload and processing
      original_file_path = file_path

      # Create temporary file for upload simulation
      temp_file = Tempfile.new(["test_image", ".jpg"])
      FileUtils.cp(original_file_path, temp_file.path)

      # Create Folio::File instance
      image_file = Folio::File::Image.new
      image_file.file = File.open(temp_file.path)
      image_file.site_id = @site.id
      image_file.save!

      # Verify extraction occurred and charset handling worked
      assert image_file.persisted?
      assert image_file.mapped_metadata[:credit_line].present?

      # Verify UTF-8 characters are properly handled (should contain Czech characters)
      assert_match(/[čšžýáíéůúČŠŽÝÁÍÉŮÚ]/, image_file.mapped_metadata[:credit_line])

      # Verify no mojibake patterns (double-encoded characters)
      assert_no_match(/Ã[^A-Za-z\s]/, image_file.mapped_metadata[:credit_line])
      assert_no_match(/Å [a-z]/, image_file.mapped_metadata[:credit_line])

      # Verify IPTC standard compliance
      creator = image_file.mapped_metadata[:creator]
      assert creator.present?, "Creator should be present"
      # Verify creator contains some meaningful content (not specifically ČTK)
      assert creator.to_s.length > 2, "Creator should contain meaningful data"
    ensure
      temp_file&.close
      temp_file&.unlink

      image_file&.destroy
    end
  end

  test "handles multiple profimedia files with consistent quality" do
    profimedia_files = Dir.glob(File.join(@test_images_dir, "profimedia-*.jpg"))
                          .select { |f| File.size(f) > 5000 }
                          .first(3) # Limit for performance

    skip if profimedia_files.empty?

    results = []

    profimedia_files.each do |original_path|
      temp_file = Tempfile.new(["test_image", ".jpg"])
      FileUtils.cp(original_path, temp_file.path)

      image_file = Folio::File::Image.new
      image_file.file = File.open(temp_file.path)
      image_file.site_id = @site.id
      image_file.save!

      # Collect results for analysis
      results << {
        filename: File.basename(original_path),
        credit_line: image_file.mapped_metadata[:credit_line].to_s,
        keywords: Array(image_file.mapped_metadata[:keywords]).join(" "),
        creator: image_file.mapped_metadata[:creator].to_s,
        has_mojibake: detect_mojibake(image_file)
      }

      temp_file.close
      temp_file.unlink
      image_file.destroy
    end

    # Verify all files processed without encoding issues
    mojibake_files = results.select { |r| r[:has_mojibake] }
    assert_empty mojibake_files, "Files with mojibake detected: #{mojibake_files.map { |r| r[:filename] }}"

    # Verify meaningful content extracted
    meaningful_results = results.count { |r| r[:credit_line].length > 5 || r[:keywords].length > 5 }
    assert meaningful_results > 0, "Should extract meaningful metadata from at least some files"
  end

  test "ExifTool configuration includes UTF-8 charset option" do
    # Verify configuration is set up correctly
    options = Rails.application.config.folio_image_metadata_exiftool_options

    assert options.is_a?(Array), "ExifTool options should be array"
    assert_includes options, "-charset", "Should include -charset flag"

    # Find the charset specification
    charset_index = options.index("-charset")
    assert charset_index, "Charset flag should be present"
    assert charset_index < options.length - 1, "Charset should have a value"

    charset_value = options[charset_index + 1]
    assert_match(/iptc=utf8/i, charset_value, "Should force UTF-8 for IPTC: #{charset_value}")
  end

  test "fallback charset candidates are available when UTF-8 fails" do
    candidates = Rails.application.config.folio_image_metadata_iptc_charset_candidates

    assert candidates.is_a?(Array), "Charset candidates should be array"
    assert_includes candidates, "utf8", "Should include UTF-8 as candidate"
    assert_includes candidates, "cp1250", "Should include CP1250 for Central European content"
    assert_includes candidates, "cp1252", "Should include CP1252 for Western European content"
  end

  test "processes IPTC reference files correctly" do
    reference_files = Dir.glob(File.join(@test_images_dir, "IPTC-PhotometadataRef-*.jpg"))
    skip if reference_files.empty?

    reference_files.first(2).each do |original_path|
      temp_file = Tempfile.new(["test_image", ".jpg"])
      FileUtils.cp(original_path, temp_file.path)

      image_file = Folio::File::Image.new
      image_file.file = File.open(temp_file.path)
      image_file.site_id = @site.id
      image_file.save!

      # IPTC reference files should have complete metadata
      assert image_file.headline.present?, "Reference file should have headline"
      assert image_file.description.present?, "Reference file should have description"
      assert image_file.mapped_metadata[:creator].present?, "Reference file should have creator"
      assert image_file.mapped_metadata[:keywords].present?, "Reference file should have keywords"
      assert image_file.mapped_metadata[:credit_line].present?, "Reference file should have credit line"

      # Should not contain encoding artifacts
      all_text = [
        image_file.headline,
        image_file.description,
        image_file.mapped_metadata[:credit_line],
        image_file.mapped_metadata[:creator].to_s,
        Array(image_file.mapped_metadata[:keywords]).join(" ")
      ].join(" ")

      assert_no_match(/\uFFFD/, all_text, "Should not contain replacement characters")
      assert_not all_text.include?("�"), "Should not contain invalid characters"

      temp_file.close
      temp_file.unlink
      image_file.destroy
    end
  end

  test "blank field protection works correctly" do
    file_path = File.join(@test_images_dir, "profimedia-0701180382.jpg")
    skip unless File.exist?(file_path)

    temp_file = nil
    image_file = nil

    begin
      temp_file = Tempfile.new(["test_image", ".jpg"])
      FileUtils.cp(file_path, temp_file.path)

      # Create file with pre-existing metadata (disable automatic extraction first)
      Rails.application.config.folio_image_metadata_extraction_enabled = false

      image_file = Folio::File::Image.new
      image_file.file = File.open(temp_file.path)
      image_file.site_id = @site.id
      image_file.description = "Pre-existing description"
      image_file.headline = "Pre-existing headline"
      image_file.save!

      # Now enable extraction and extract manually (should not overwrite existing values)
      Rails.application.config.folio_image_metadata_extraction_enabled = true
      image_file.extract_metadata!(force: true)

      # Reload and verify values weren't overwritten
      image_file.reload
      assert_equal "Pre-existing description", image_file.description
      assert_equal "Pre-existing headline", image_file.headline

      # Metadata should be extracted to JSON but not overwrite user fields
      assert_not_nil image_file.file_metadata, "Metadata should be extracted to JSON"
    ensure
      temp_file&.close
      temp_file&.unlink

      image_file&.destroy
    end
  end

  test "handles files with minimal metadata gracefully" do
    # Create minimal test image (might not have rich metadata)
    test_files = Dir.glob(File.join(@test_images_dir, "*.jpg"))
                    .reject { |f| f.include?("profimedia") || f.include?("IPTC") }
                    .first(2)

    skip if test_files.empty?

    test_files.each do |original_path|
      temp_file = Tempfile.new(["test_image", ".jpg"])
      FileUtils.cp(original_path, temp_file.path)

      image_file = Folio::File::Image.new
      image_file.file = File.open(temp_file.path)
      image_file.site_id = @site.id

      # Should not raise errors even with minimal metadata
      assert_nothing_raised do
        image_file.save!
      end

      assert image_file.persisted?, "File should save successfully"

      # Fields might be blank but should not contain invalid data
      [image_file.description, image_file.mapped_metadata[:credit_line], image_file.headline].each do |field|
        if field.present?
          assert_no_match(/\uFFFD/, field, "Should not contain replacement characters")
          assert_not field.include?("�"), "Should not contain invalid characters"
        end
      end

      temp_file.close
      temp_file.unlink
      image_file.destroy
    end
  end

  private
    def detect_mojibake(image_file)
      # Check common fields for mojibake patterns
      text_fields = [
        image_file.description,
        image_file.mapped_metadata[:credit_line],
        image_file.headline,
        image_file.mapped_metadata[:creator].to_s,
        Array(image_file.mapped_metadata[:keywords]).join(" ")
      ].compact

      text_fields.any? do |field|
        # Common mojibake patterns for Czech/Slovak text
        field.match?(/[ÄÅÃ][^A-Za-z\s]/) ||  # Double-encoded Czech chars
        field.include?("\uFFFD") ||            # Replacement character
        field.include?("�") ||                # Invalid character display
        field.match?(/Å\s[a-z]/) ||          # Common pattern like "Å ubrt"
        field.match?(/Ã[^A-Za-z\s]{2,}/)     # Multiple garbled chars
      end
    end
end

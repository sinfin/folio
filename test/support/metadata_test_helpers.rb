# frozen_string_literal: true

module MetadataTestHelpers
  # Helper methods for testing image metadata extraction and charset handling

  def create_test_image_file(filename, attributes = {})
    """
    Creates a test image file with metadata extraction.

    Args:
      filename: Name of test file in metadata_test_images fixture directory
      attributes: Hash of attributes to set before save

    Returns:
      Folio::File instance with extracted metadata
    """
    # Rails.root points to test/dummy in gems, we need to go up to main gem root
    gem_root = Rails.root.parent.parent
    test_images_dir = gem_root.join("test", "fixtures", "folio", "metadata_test_images")
    original_path = test_images_dir.join(filename)

    skip "Test file #{filename} not found" unless File.exist?(original_path)

    # Create temporary copy for upload simulation
    temp_file = Tempfile.new(["test_image", ".jpg"])
    FileUtils.cp(original_path, temp_file.path)

    image_file = Folio::File.new
    attributes.each { |key, value| image_file.send("#{key}=", value) }
    image_file.file = File.open(temp_file.path)
    image_file.save!
    image_file.reload

    # Store temp file for cleanup
    image_file.instance_variable_set(:@temp_file, temp_file)
    image_file
  end

  def cleanup_test_image(image_file)
    """
    Cleans up test image file and temporary files.
    """
    return unless image_file

    image_file.file&.close
    temp_file = image_file.instance_variable_get(:@temp_file)
    if temp_file
      temp_file.close
      temp_file.unlink
    end
    image_file.destroy if image_file.persisted?
  end

  def assert_no_mojibake(text, message = nil)
    """
    Asserts that text doesn't contain common Czech/Slovak mojibake patterns.
    """
    return if text.blank?

    message ||= "Text contains mojibake patterns: #{text[0..100]}..."

    # Common mojibake patterns for Czech text
    mojibake_patterns = [
      /[ÄÅÃ][^A-Za-z\s]/,     # Double-encoded Czech chars like ÄŒ, Å¡, Ã¡
      /\uFFFD/,                # Unicode replacement character
      /Å\s[a-z]/,             # Common pattern like "Å ubrt"
      /Ã[^A-Za-z\s]{2,}/,     # Multiple consecutive mojibake chars
      /VolebnÃ.*KampaÅ/,      # Specific Czech political term pattern
      /ÄŒesk.*BudÄ›/          # České Budějovice pattern
    ]

    mojibake_patterns.each do |pattern|
      assert_no_match pattern, text, message
    end

    # Check for replacement character display
    assert_not text.include?("�"), "#{message} (contains replacement character display)"
  end

  def assert_valid_czech_text(text, message = nil)
    """
    Asserts that text contains valid Czech characters and doesn't have encoding issues.
    """
    return if text.blank?

    message ||= "Text doesn't contain valid Czech characters: #{text[0..100]}..."

    # Should not contain mojibake
    assert_no_mojibake(text, message)

    # If it contains Czech letters, they should be properly encoded
    if text.match?(/[čšřžýáíéůúňťď]/i)
      # Text claims to have Czech chars - verify they're real Unicode
      text.each_char do |char|
        if char.match?(/[čšřžýáíéůúňťď]/i)
          # Char should be properly encoded Unicode, not mojibake
          assert char.valid_encoding?, "#{message} (invalid encoding for character: #{char})"
          assert_not char.bytes.any? { |b| b > 127 && b < 160 }, "#{message} (suspicious byte range for: #{char})"
        end
      end
    end
  end

  def detect_charset_issues(text)
    """
    Detects potential charset issues in text and returns diagnostic info.

    Returns:
      Hash with diagnostic information about potential encoding issues
    """
    return { clean: true } if text.blank?

    issues = {
      clean: true,
      mojibake_patterns: [],
      suspicious_chars: [],
      byte_analysis: {}
    }

    # Check for mojibake patterns
    mojibake_regexes = {
      double_encoded_czech: /[ÄÅÃ][^A-Za-z\s]/,
      replacement_char: /\uFFFD/,
      specific_names: /Å\s[a-z]/,
      consecutive_mojibake: /Ã[^A-Za-z\s]{2,}/
    }

    mojibake_regexes.each do |name, pattern|
      if text.match?(pattern)
        issues[:clean] = false
        issues[:mojibake_patterns] << name
      end
    end

    # Analyze suspicious characters
    text.each_char.with_index do |char, index|
      if char.ord > 127 && char.ord < 160  # Control character range
        issues[:clean] = false
        issues[:suspicious_chars] << { char: char, position: index, ord: char.ord }
      elsif char == "�"  # Replacement character display
        issues[:clean] = false
        issues[:suspicious_chars] << { char: char, position: index, ord: char.ord, type: :replacement }
      end
    end

    # Byte analysis for encoding detection
    issues[:byte_analysis] = {
      total_bytes: text.bytesize,
      char_count: text.length,
      has_multibyte: text.bytesize != text.length,
      encoding: text.encoding.name,
      valid_encoding: text.valid_encoding?
    }

    issues
  end

  def assert_iptc_standard_compliance(image_file)
    """
    Asserts that image file follows IPTC Photo Metadata Standard.
    """
    # Multi-value fields should be arrays
    [:creator, :keywords, :subject_codes, :scene_codes].each do |field|
      value = image_file.send(field)
      if value.present?
        assert value.is_a?(Array), "#{field} should be array per IPTC standard"
        assert value.all? { |item| item.is_a?(String) && !item.blank? }, "#{field} should contain non-blank strings"
      end
    end

    # String fields should be strings
    [:headline, :description, :credit_line, :source, :copyright_notice].each do |field|
      value = image_file.send(field)
      if value.present?
        assert value.is_a?(String), "#{field} should be string"
      end
    end

    # Boolean fields should be boolean
    if image_file.respond_to?(:copyright_marked) && image_file.copyright_marked.present?
      assert [true, false].include?(image_file.copyright_marked), "copyright_marked should be boolean"
    end

    # Country code constraints
    if image_file.country_code.present?
      assert image_file.country_code.length <= 2, "country_code should be max 2 chars (ISO 3166-1)"
      assert image_file.country_code.match?(/\A[A-Z]{1,2}\z/), "country_code should be uppercase letters"
    end

    # GPS coordinates validation
    if image_file.gps_latitude.present?
      assert image_file.gps_latitude.is_a?(Numeric), "gps_latitude should be numeric"
      assert image_file.gps_latitude.between?(-90, 90), "gps_latitude should be valid range"
    end

    if image_file.gps_longitude.present?
      assert image_file.gps_longitude.is_a?(Numeric), "gps_longitude should be numeric"
      assert image_file.gps_longitude.between?(-180, 180), "gps_longitude should be valid range"
    end
  end

  def extract_raw_exiftool_metadata(file_path, options = nil)
    """
    Extracts raw metadata using ExifTool for testing purposes.

    Returns:
      Hash of raw metadata or nil if extraction fails
    """
    require "open3"
    require "json"

    options ||= Rails.application.config.folio_image_metadata_exiftool_options
    command = ["exiftool", "-j", *options, file_path.to_s]

    stdout, stderr, status = Open3.capture3(*command)

    if status.success?
      JSON.parse(stdout).first
    else
      Rails.logger.warn "ExifTool extraction failed: #{stderr}"
      nil
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse ExifTool JSON output: #{e.message}"
    nil
  end
end

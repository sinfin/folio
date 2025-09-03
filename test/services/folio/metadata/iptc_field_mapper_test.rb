# frozen_string_literal: true

require "test_helper"

class Folio::Metadata::IptcFieldMapperTest < ActiveSupport::TestCase
  def setup
    @mapper = Folio::Metadata::IptcFieldMapper
  end

  # Test basic field mapping functionality
  test "maps XMP fields with correct precedence" do
    metadata = {
      "XMP-photoshop:Headline" => "XMP Headline",
      "Headline" => "IPTC Headline"
    }

    result = @mapper.map_metadata(metadata)

    # XMP should take precedence over IPTC-IIM
    assert_equal "XMP Headline", result[:headline]
  end

  test "falls back to IPTC-IIM when XMP missing" do
    metadata = {
      "Headline" => "IPTC Headline"
    }

    result = @mapper.map_metadata(metadata)

    assert_equal "IPTC Headline", result[:headline]
  end

  test "handles IPTC group prefix correctly" do
    metadata = {
      "IPTC:By-line" => "John Doe",
      "IPTC:Credit" => "Photo Agency"
    }

    result = @mapper.map_metadata(metadata)

    assert_equal "John Doe", result[:creator]
    assert_equal "Photo Agency", result[:credit_line]
  end

  # Test charset encoding scenarios
  test "processes clean UTF-8 data correctly" do
  metadata = {
    "IPTC:By-line" => "ČTK / Šimánek Vít",
    "IPTC:Credit" => "České noviny",
    "XMP-dc:Subject" => ["volby", "političky", "Česká republika"]
  }

  result = @mapper.map_metadata(metadata)

  assert_equal "ČTK / Šimánek Vít", result[:creator]
  assert_equal "České noviny", result[:credit_line]
  # Keywords map from XMP-dc:Subject, not IPTC:Keywords
  assert_equal ["volby", "političky", "Česká republika"], result[:keywords]
end

  test "handles CodedCharacterSet information" do
    metadata = {
      "IPTC:CodedCharacterSet" => "\u001b%G", # UTF-8 indicator
      "IPTC:By-line" => "Český autor",
      "Caption-Abstract" => "Popis s českými znaky"
    }

    result = @mapper.map_metadata(metadata)

    # Should process without attempting additional encoding repair
    assert_equal "Český autor", result[:creator]
    assert_equal "Popis s českými znaky", result[:description]
  end

  # Test array handling
  test "converts single values to arrays for multi-value fields" do
    metadata = {
      "XMP-dc:Creator" => "Single Creator",
      "XMP-dc:Subject" => "Single Keyword"
    }

    result = @mapper.map_metadata(metadata)

    assert_equal "Single Creator", result[:creator]
    assert_equal ["Single Keyword"], result[:keywords]
  end

  test "preserves arrays for multi-value fields" do
    metadata = {
      "XMP-dc:Creator" => ["Creator One", "Creator Two"],
      "XMP-dc:Subject" => ["Keyword1", "Keyword2", "Keyword3"]
    }

    result = @mapper.map_metadata(metadata)

    assert_equal "Creator One, Creator Two", result[:creator]
    assert_equal ["Keyword1", "Keyword2", "Keyword3"], result[:keywords]
  end

  test "filters blank values from arrays consistently" do
  metadata = {
    "XMP-dc:Creator" => ["John Doe", "", "   ", "Jane Smith"],
    "XMP-dc:Subject" => ["keyword1", nil, "", "keyword2"]
  }

  result = @mapper.map_metadata(metadata)

  # Both creator and keywords should filter out blank values consistently
  assert_equal "John Doe, Jane Smith", result[:creator]
  assert_equal ["keyword1", "keyword2"], result[:keywords]
end

  # Test complex field processors
  test "processes headline arrays correctly" do
    metadata = {
      "XMP-photoshop:Headline" => ["Main Headline", "Sub Headline"]
    }

    result = @mapper.map_metadata(metadata)

    assert_equal "Main Headline, Sub Headline", result[:headline]
  end

  test "handles copyright marked boolean field" do
    metadata = {
      "XMP-xmpRights:Marked" => true
    }

    result = @mapper.map_metadata(metadata)

    assert_equal true, result[:copyright_marked]
  end

  test "processes GPS coordinates with -n flag format" do
    metadata = {
      "GPSLatitude" => 50.0755,
      "GPSLongitude" => 14.4378
    }

    result = @mapper.map_metadata(metadata)

    assert_equal 50.0755, result[:gps_latitude]
    assert_equal 14.4378, result[:gps_longitude]
  end

  test "handles capture date with timezone" do
  metadata = {
    "DateTimeOriginal" => "2024:03:15 14:30:00+02:00"
  }

  result = @mapper.map_metadata(metadata)

  # Capture date processor extracts just the time part, not full hash
  capture_result = result[:capture_date]
  assert capture_result.is_a?(Time), "Capture date should be Time object"
  assert_equal 2024, capture_result.year
  assert_equal 3, capture_result.month
  assert_equal 15, capture_result.day
end

  # Test country code validation
  test "validates and truncates country code" do
    metadata = {
      "XMP-iptcCore:CountryCode" => "CZECH" # Too long
    }

    result = @mapper.map_metadata(metadata)

    assert_equal "CZ", result[:country_code]
  end

  # Test source derivation from credit_line
  test "derives source from credit_line when source blank" do
    metadata = {
      "XMP-iptcCore:CreditLine" => "Photographer Name / Agency Name / Profimedia",
      # No source field
    }

    result = @mapper.map_metadata(metadata)

    assert_equal "Profimedia", result[:source]
  end

  test "preserves explicit source over derived" do
    metadata = {
      "XMP-iptcCore:Source" => "Explicit Source",
      "XMP-iptcCore:CreditLine" => "Photographer / Agency / Profimedia"
    }

    result = @mapper.map_metadata(metadata)

    assert_equal "Explicit Source", result[:source]
  end

  # Test provider detection heuristics
  test "detects common providers in metadata" do
    metadata = {
      "IPTC:Credit" => "Getty Images contributor content",
      "IPTC:Source" => "" # blank
    }

    result = @mapper.map_metadata(metadata)

    # Should detect Getty in credit and use as source
    assert_match(/Getty/, result[:source].to_s)
  end

  # Test Lang Alt handling
  test "extracts correct locale from Lang Alt structure" do
    metadata = {
      "XMP-dc:Description" => {
        "lang" => "x-default",
        "en" => "English Description",
        "cs" => "Český popis"
      }
    }

    # Test Czech priority
    result = @mapper.map_metadata(metadata, locale: :cs)
    assert_equal "Český popis", result[:description]

    # Test English fallback
    result = @mapper.map_metadata(metadata, locale: :en)
    assert_equal "English Description", result[:description]
  end

  test "handles malformed or empty metadata gracefully" do
    # Empty metadata
    result = @mapper.map_metadata({})
    assert result.is_a?(Hash)
    assert result.empty?

    # Nil values
    result = @mapper.map_metadata({ "Headline" => nil })
    assert_not result.key?(:headline)

    # Malformed arrays
    result = @mapper.map_metadata({ "XMP-dc:Subject" => [nil, "", "   "] })
    assert_equal [], result[:keywords]
  end

  # Integration test with real metadata structure
  test "processes complete metadata structure correctly" do
    metadata = {
      "IPTC:CodedCharacterSet" => "\u001b%G",
      "XMP-photoshop:Headline" => "Breaking News",
      "XMP-dc:Description" => { "x-default" => "Important event coverage" },
      "XMP-dc:Creator" => ["John Photographer", "Jane Journalist"],
      "XMP-iptcCore:CreditLine" => "News Agency / Profimedia",
      "XMP-dc:Subject" => ["news", "politics", "coverage"],
      "XMP-iptcCore:CountryCode" => "CZ",
      "GPSLatitude" => 50.0755,
      "GPSLongitude" => 14.4378,
      "DateTimeOriginal" => "2024:03:15 14:30:00",
      "Make" => "Canon",
      "Model" => "EOS R5"
    }

    result = @mapper.map_metadata(metadata)

    # Verify all fields are correctly mapped
    assert_equal "Breaking News", result[:headline]
    assert_equal "Important event coverage", result[:description]
    assert_equal "John Photographer, Jane Journalist", result[:creator]
    assert_equal "News Agency / Profimedia", result[:credit_line]
    assert_equal "Profimedia", result[:source] # Derived from credit_line
    assert_equal ["news", "politics", "coverage"], result[:keywords]
    assert_equal "CZ", result[:country_code]
    assert_equal 50.0755, result[:gps_latitude]
    assert_equal 14.4378, result[:gps_longitude]
    capture_result = result[:capture_date]
    assert capture_result.is_a?(Time), "Capture date should be Time object"
    assert_equal 2024, capture_result.year
    assert_equal "Canon", result[:camera_make]
    assert_equal "EOS R5", result[:camera_model]
  end
end

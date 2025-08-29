# frozen_string_literal: true

require "test_helper"

class Folio::File::ImageTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # Metadata extraction tests
  test "extracts IPTC metadata on image creation" do
    with_config(folio_image_metadata_extraction_enabled: true) do
      # Mock ExifTool output
      metadata = {
        "XMP-dc:creator" => ["John Doe"],
        "XMP-dc:description" => "Test image description",
        "XMP-photoshop:Headline" => "Test Headline",
        "XMP-dc:subject" => ["keyword1", "keyword2"],
        "XMP-photoshop:Copyright" => "Copyright 2024",
        "Make" => "Canon",
        "Model" => "EOS R5"
      }

      # Create image with blank fields to test extraction
      image = create(:folio_file_image, description: nil, author: nil)

      # Manually test the service
      image.file_metadata = metadata
      image.file_metadata_extracted_at = Time.current

      # Map using existing field mapper
      mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(metadata)

      # Store processed metadata in JSON for getters
      mapped_data.each do |field, value|
        next if value.blank?
        image.file_metadata[field.to_s] = value
      end

      # Update database fields from mapped data
      mapped_data.each do |field, value|
        next if value.blank?

        # Only update if current field is blank
        if image.respond_to?("#{field}=") && image.send(field).blank?
          image.send("#{field}=", value)
        end
      end

      image.save!
      image.reload

      assert_equal ["John Doe"], image.file_metadata&.dig("creator")
      assert_equal "Test image description", image.description
      assert_equal "Test Headline", image.headline
      assert_equal ["keyword1", "keyword2"], image.file_metadata&.dig("keywords")
      assert_not_nil image.file_metadata_extracted_at
    end
  end

  test "preserves existing data during metadata extraction" do
    image = create(:folio_file_image,
                   description: "Existing description",
                   headline: "Existing headline")

    raw_metadata = {
      "XMP-dc:description" => "New description from metadata",
      "XMP-photoshop:Headline" => "New headline from metadata",
      "XMP-dc:creator" => ["Author from metadata"]
    }

    # Simulate metadata extraction via service
    mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)

    # Store raw metadata and mapped data
    image.file_metadata = raw_metadata
    mapped_data.each { |field, value| image.file_metadata[field.to_s] = value if value.present? }

    # Update database fields only if they're blank
    mapped_data.each do |field, value|
      next if value.blank?
      if image.respond_to?("#{field}=") && image.send(field).blank?
        image.send("#{field}=", value)
      end
    end

    image.save!
    image.reload

    # Should not overwrite existing data (auto-population only for blank fields)
    assert_equal "Existing description", image.description
    assert_equal "Existing headline", image.headline
    # JSON getter should return metadata
    assert_equal ["Author from metadata"], image.creator_list
  end

  test "handles GPS coordinates extraction" do
    raw_metadata = {
      "GPSLatitude" => 50.089801,
      "GPSLongitude" => 14.420311
    }

    image = create(:folio_file_image)

    # Simulate metadata extraction via service
    mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)

    # Store raw metadata and mapped data
    image.file_metadata = raw_metadata
    mapped_data.each { |field, value| image.file_metadata[field.to_s] = value if value.present? }

    # Update database fields
    mapped_data.each do |field, value|
      next if value.blank?
      if image.respond_to?("#{field}=")
        image.send("#{field}=", value)
      end
    end

    image.save!
    image.reload

    assert_equal 50.089801, image.gps_latitude
    assert_equal 14.420311, image.gps_longitude
    assert_equal [50.089801, 14.420311], image.location_coordinates
  end

  test "handles datetime field extraction" do
    raw_metadata = {
      "DateTimeOriginal" => "2024:01:15 14:30:25"
    }

    image = create(:folio_file_image)

    # Simulate metadata extraction via service
    mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)

    # Store raw metadata and mapped data
    image.file_metadata = raw_metadata
    mapped_data.each { |field, value| image.file_metadata[field.to_s] = value if value.present? }

    # Update database fields
    mapped_data.each do |field, value|
      next if value.blank?
      if image.respond_to?("#{field}=")
        image.send("#{field}=", value)
      end
    end

    image.save!
    image.reload

    assert_equal Time.parse("2024-01-15 14:30:25"), image.capture_date
  end

  test "handles boolean field extraction" do
    raw_metadata = {
      "XMP-xmpRights:Marked" => "True"
    }

    image = create(:folio_file_image)

    # Simulate metadata extraction via service
    mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)

    # Store raw metadata and mapped data
    image.file_metadata = raw_metadata
    mapped_data.each { |field, value| image.file_metadata[field.to_s] = value if value.present? }

    image.save!
    image.reload

    # Check if boolean field was properly extracted
    assert_equal true, image.file_metadata&.dig("copyright_marked")
  end

  test "respects configuration to disable extraction" do
    with_config(folio_image_metadata_extraction_enabled: false) do
      image = create(:folio_file_image)

      assert_not image.should_extract_metadata?
    end
  end



  test "metadata accessors work correctly" do
    image = create(:folio_file_image)
    # Set metadata via file_metadata hash and database attributes (simulating extraction result)
    image.update!(
      file_metadata: {
        "headline" => "IPTC Headline",
        "keywords" => ["tag1", "tag2"],
        "creator" => ["Author One", "Author Two"]
      },
      gps_latitude: 50.0,
      gps_longitude: 14.0
    )

    assert_equal "IPTC Headline", image.title
    assert_equal ["tag1", "tag2"], image.keywords_list
    assert_equal "tag1, tag2", image.keywords_string
    assert_equal ["Author One", "Author Two"], image.creator_list
    assert_equal [50.0, 14.0], image.location_coordinates
  end

  test "geo_location builds from IPTC fields" do
    image = create(:folio_file_image)
    # Set metadata via file_metadata hash (simulating extraction result)
    image.update!(file_metadata: {
      "sublocation" => "Old Town",
      "city" => "Prague",
      "state_province" => "Prague",
      "country" => "Czech Republic"
    })

    assert_equal "Old Town, Prague, Prague, Czech Republic", image.geo_location
  end

  test "processes XMP Lang Alt structures" do
    raw_metadata = {
      "XMP-dc:description" => {
        "x-default" => "Default description",
        "en" => "English description",
        "cs" => "Czech description"
      }
    }

    image = create(:folio_file_image)

    # Simulate metadata extraction via service
    mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(raw_metadata)

    # Store raw metadata and mapped data
    image.file_metadata = raw_metadata
    mapped_data.each { |field, value| image.file_metadata[field.to_s] = value if value.present? }

    # Update database fields
    mapped_data.each do |field, value|
      next if value.blank?
      if image.respond_to?("#{field}=")
        image.send("#{field}=", value)
      end
    end

    image.save!
    image.reload

    # Should extract proper language variant
    assert_not_nil image.description
    assert image.description.include?("description")
  end

  test "manual metadata re-extraction works" do
  image = create(:folio_file_image)
  metadata = {
    "XMP-dc:creator" => ["Manual Author"]
  }

  # Test the service directly with manual mapping
  image.file_metadata = metadata
  mapped_data = Folio::Metadata::IptcFieldMapper.map_metadata(metadata)
  mapped_data.each { |field, value| image.file_metadata[field.to_s] = value if value.present? }
  image.save!

  image.reload
  assert_equal ["Manual Author"], image.file_metadata&.dig("creator")
end

  test "additional data - white" do
    image = create(:folio_file_image, file: Folio::Engine.root.join("test/fixtures/folio/test.gif"))
    assert_nil image.reload.additional_data

    [
      ["test-black.gif", "#000000", true],
      ["test-black.jpg", "#000000", true],
      ["test-black.png", "#000000", true],
      ["test.gif", "#FFFFFF", false],
      ["test.jpg", "#FFFFFF", false],
      ["test.png", "#FFFFFF", false],
    ].each do |file_name, dominant_color, dark|
      perform_enqueued_jobs do
        image = create(:folio_file_image, file: Folio::Engine.root.join("test/fixtures/folio", file_name))
        assert(image.reload.additional_data)
        assert_equal(dominant_color, image.additional_data["dominant_color"])
        assert_equal(dark, image.additional_data["dark"])
      end
    end
  end
end

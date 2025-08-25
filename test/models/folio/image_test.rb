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
      image.stub(:extract_raw_metadata_with_exiftool, metadata) do
        image.extract_image_metadata_sync

        assert_equal ["John Doe"], image.creator
        assert_equal "Test image description", image.description
        assert_equal "Test Headline", image.headline
        assert_equal ["keyword1", "keyword2"], image.keywords
        assert_equal "Copyright 2024", image.copyright_notice
        assert_equal "Canon", image.camera_make
        assert_equal "EOS R5", image.camera_model
      end
    end
  end

  test "preserves existing data during metadata extraction" do
    image = create(:folio_file_image,
                   description: "Existing description",
                   headline: "Existing headline")

    metadata = {
      "XMP-dc:description" => "New description from metadata",
      "XMP-photoshop:Headline" => "New headline from metadata",
      "XMP-dc:creator" => ["Author from metadata"]
    }

    image.stub(:extract_raw_metadata_with_exiftool, metadata) do
      image.extract_image_metadata_sync

      # Should not overwrite existing data (auto-population only for blank fields)
      assert_equal "Existing description", image.description
      assert_equal "Existing headline", image.headline
      # JSON getter should return metadata
      assert_equal ["Author from metadata"], image.creator
    end
  end

  test "handles GPS coordinates extraction" do
    metadata = {
      "GPSLatitude" => 50.089801,
      "GPSLongitude" => 14.420311
    }

    image = create(:folio_file_image)
    image.stub(:extract_raw_metadata_with_exiftool, metadata) do
      image.extract_image_metadata_sync

      assert_equal 50.089801, image.gps_latitude
      assert_equal 14.420311, image.gps_longitude
      assert_equal [50.089801, 14.420311], image.location_coordinates
    end
  end

  test "handles datetime field extraction" do
    metadata = {
      "DateTimeOriginal" => "2024:01:15 14:30:25"
    }

    image = create(:folio_file_image)
    image.stub(:extract_raw_metadata_with_exiftool, metadata) do
      image.extract_image_metadata_sync

      assert_equal Time.parse("2024-01-15 14:30:25"), image.capture_date
    end
  end

  test "handles boolean field extraction" do
    metadata = {
      "XMP-xmpRights:Marked" => "True"
    }

    image = create(:folio_file_image)
    image.stub(:extract_raw_metadata_with_exiftool, metadata) do
      image.extract_image_metadata_sync

      assert_equal true, image.copyright_marked
    end
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
        "Headline" => "IPTC Headline",
        "Keywords" => ["tag1", "tag2"],
        "Artist" => ["Author One", "Author Two"]
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
      "XMP-iptcCore:Location" => "Old Town",
      "XMP-photoshop:City" => "Prague",
      "XMP-photoshop:State" => "Prague",
      "XMP-iptcCore:CountryName" => "Czech Republic"
    })

    assert_equal "Old Town, Prague, Prague, Czech Republic", image.geo_location
  end

  test "processes XMP Lang Alt structures" do
    metadata = {
      "XMP-dc:description" => {
        "x-default" => "Default description",
        "en" => "English description",
        "cs" => "Czech description"
      }
    }

    image = create(:folio_file_image)
    image.stub(:extract_raw_metadata_with_exiftool, metadata) do
      image.extract_image_metadata_sync

      # Should extract proper language variant
      assert_not_nil image.description
      assert image.description.include?("description")
    end
  end

  test "manual metadata re-extraction works" do
    image = create(:folio_file_image)
    metadata = {
      "XMP-dc:creator" => ["Manual Author"]
    }

    image.stub(:extract_raw_metadata_with_exiftool, metadata) do
      image.extract_metadata!

      assert_equal ["Manual Author"], image.creator
    end
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

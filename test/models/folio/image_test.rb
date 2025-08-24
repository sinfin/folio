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
        image.extract_image_metadata

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
      image.map_iptc_metadata(metadata)

      # Should not overwrite existing data
      assert_equal "Existing description", image.description
      assert_equal "Existing headline", image.headline
      # But should add new data
      assert_equal ["Author from metadata"], image.creator
    end
  end

  test "handles GPS coordinates extraction" do
    metadata = {
      "GPSLatitude" => "50 deg 5' 23.28\" N",
      "GPSLongitude" => "14 deg 25' 15.12\" E"
    }

    image = create(:folio_file_image)
    image.map_iptc_metadata(metadata)

    assert_in_delta 50.089801, image.gps_latitude, 0.001
    assert_in_delta 14.420867, image.gps_longitude, 0.001
  end

  test "handles datetime field extraction" do
    metadata = {
      "DateTimeOriginal" => "2024:01:15 14:30:25"
    }

    image = create(:folio_file_image)
    image.map_iptc_metadata(metadata)

    assert_equal Time.parse("2024-01-15 14:30:25"), image.capture_date
  end

  test "handles boolean field extraction" do
    metadata = {
      "XMP-xmpRights:Marked" => "True"
    }

    image = create(:folio_file_image)
    image.map_iptc_metadata(metadata)

    assert_equal true, image.copyright_marked
  end

  test "respects configuration to disable extraction" do
    with_config(folio_image_metadata_extraction_enabled: false) do
      image = create(:folio_file_image)

      assert_not image.should_extract_metadata?
    end
  end

  test "skips configured fields during extraction" do
    with_config(folio_image_metadata_skip_fields: [:urgency, :category]) do
      metadata = {
        "XMP-photoshop:Urgency" => "1",
        "XMP-photoshop:Category" => "News",
        "XMP-dc:creator" => ["John Doe"]
      }

      image = create(:folio_file_image)
      image.map_iptc_metadata(metadata)

      # Should skip configured fields
      assert_nil image.urgency
      assert_nil image.category
      # But still process others
      assert_equal ["John Doe"], image.creator
    end
  end

  test "metadata accessors work correctly" do
    image = create(:folio_file_image,
                   headline: "IPTC Headline",
                   keywords: ["tag1", "tag2"],
                   creator: ["Author One", "Author Two"],
                   gps_latitude: 50.0,
                   gps_longitude: 14.0)

    assert_equal "IPTC Headline", image.title
    assert_equal ["tag1", "tag2"], image.keywords_list
    assert_equal "tag1, tag2", image.keywords_string
    assert_equal ["Author One", "Author Two"], image.creator_list
    assert_equal [50.0, 14.0], image.location_coordinates
  end

  test "geo_location builds from IPTC fields" do
    image = create(:folio_file_image,
                   sublocation: "Old Town",
                   city: "Prague",
                   state_province: "Prague",
                   country: "Czech Republic")

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

    # With default locale priority (en first)
    image.map_iptc_metadata(metadata)
    assert_equal "English description", image.description
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

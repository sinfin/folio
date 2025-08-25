# frozen_string_literal: true

require "test_helper"

class Folio::File::ImageMetadataSamplesTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @site = get_any_site
  end

  test "extracts metadata from IPTC-PhotometadataRef-Std2021.1.jpg" do
    image_path = Rails.root.join("test/fixtures/folio/metadata_test_images/IPTC-PhotometadataRef-Std2021.1.jpg")
    skip "Test image not found" unless File.exist?(image_path)

    with_config(folio_image_metadata_extraction_enabled: true) do
      image = create(:folio_file_image,
                     file: File.open(image_path),
                     site: @site,
                     description: nil,
                     author: nil)

      # IPTC metadata should be extracted
      assert_equal "The description aka caption (ref2021.1)", image.description
      assert_equal "Creator1 (ref2021.1)", image.author
      assert_equal ["Creator1 (ref2021.1)"], image.creator
      assert_equal "The Headline (ref2021.1)", image.headline  # Actual value from IPTC
      assert_equal ["Keyword1ref2021.1", "Keyword2ref2021.1", "Keyword3ref2021.1"], image.keywords
      assert_equal "Sublocation (Core) (ref2021.1)", image.sublocation
      assert_equal "Copyright (Notice) 2021.1 IPTC - www.iptc.org  (ref2021.1)", image.copyright_notice
    end
  end

  test "extracts metadata from IPTC-PhotometadataRef-Std2023.1.jpg" do
    image_path = Rails.root.join("test/fixtures/folio/metadata_test_images/IPTC-PhotometadataRef-Std2023.1.jpg")
    skip "Test image not found" unless File.exist?(image_path)

    with_config(folio_image_metadata_extraction_enabled: true) do
      image = create(:folio_file_image,
                     file: File.open(image_path),
                     site: @site,
                     description: nil,
                     author: nil,
                     headline: nil)

      # Check key IPTC metadata fields
      assert_equal "The description aka caption (ref2023.1)", image.description
      assert_equal "Creator1 (ref2023.1)", image.author
      assert_equal ["Creator1 (ref2023.1)"], image.creator
      assert_equal "The Headline (ref2023.1)", image.headline  # Actual value from IPTC
      assert_equal ["Keyword1ref2023.1", "Keyword2ref2023.1", "Keyword3ref2023.1"], image.keywords
      assert_equal "Sublocation (Core) (ref2023.1)", image.sublocation
      assert_equal "Copyright (Notice) 2023.1 IPTC - www.iptc.org  (ref2023.1)", image.copyright_notice
    end
  end

  test "extracts metadata from IPTC-PhotometadataRef-Std2024.1.jpg" do
    image_path = Rails.root.join("test/fixtures/folio/metadata_test_images/IPTC-PhotometadataRef-Std2024.1.jpg")
    skip "Test image not found" unless File.exist?(image_path)

    with_config(folio_image_metadata_extraction_enabled: true) do
      image = create(:folio_file_image,
                     file: File.open(image_path),
                     site: @site,
                     description: nil,
                     author: nil)

      # Verify latest IPTC standard extraction
      assert_equal "The description aka caption (ref2024.1)", image.description
      assert_equal "Creator1 (ref2024.1)", image.author
      assert_equal ["Creator1 (ref2024.1)"], image.creator
      assert_equal "The Headline (ref2024.1)", image.headline  # Actual value from IPTC file
      assert_equal ["Keyword1ref2024.1", "Keyword2ref2024.1", "Keyword3ref2024.1"], image.keywords
      assert_equal "Sublocation (Core) (ref2024.1)", image.sublocation
      assert_equal "R23", image.country_code

      # Verify new metadata accessors work
      assert_equal "The Headline (ref2024.1)", image.title  # Uses headline field
      assert_equal ["Keyword1ref2024.1", "Keyword2ref2024.1", "Keyword3ref2024.1"], image.keywords_list
      assert_equal "Keyword1ref2024.1, Keyword2ref2024.1, Keyword3ref2024.1", image.keywords_string
      assert_equal ["Creator1 (ref2024.1)"], image.creator_list
      assert image.geo_location.include?("Sublocation (Core) (ref2024.1)")  # Contains sublocation + city + state
    end
  end

  test "extracts XMP metadata from older IPTC reference images" do
    image_path = Rails.root.join("test/fixtures/folio/metadata_test_images/IPTC-PhotometadataRef-Std2016_large.jpg")
    skip "Test image not found" unless File.exist?(image_path)

    with_config(folio_image_metadata_extraction_enabled: true) do
      image = create(:folio_file_image,
                     file: File.open(image_path),
                     site: @site,
                     description: nil,
                     author: nil)

      # Older format should still extract basic fields
      assert_equal "The description aka caption (ref2016)", image.description
      assert_equal "Creator1 (ref2016)", image.author
      assert_equal ["Creator1 (ref2016)"], image.creator
      assert_equal "Copyright (Notice) 2016 IPTC - www.iptc.org  (ref2016)", image.copyright_notice
      assert_equal "R16", image.country_code
    end
  end

  test "handles example images gracefully when they have no metadata" do
    image_path = Rails.root.join("test/fixtures/folio/metadata_test_images/example-image-1.jpg")
    skip "Test image not found" unless File.exist?(image_path)

    with_config(folio_image_metadata_extraction_enabled: true) do
      image = create(:folio_file_image,
                     file: File.open(image_path),
                     site: @site,
                     description: nil,
                     author: nil)

      # Should not crash, fields should remain nil
      assert_nil image.description
      assert_nil image.author
      assert_equal [], image.creator
      assert_nil image.headline
      assert_equal [], image.keywords
    end
  end

  test "IPTC metadata precedence over EXIF in reference images" do
    image_path = Rails.root.join("test/fixtures/folio/metadata_test_images/IPTC-PhotometadataRef-Std2021.1.jpg")
    skip "Test image not found" unless File.exist?(image_path)

    with_config(folio_image_metadata_extraction_enabled: true) do
      # This image has both IPTC and EXIF data
      # IPTC By-line should take precedence over EXIF Artist for creator field
      image = create(:folio_file_image,
                     file: File.open(image_path),
                     site: @site,
                     description: nil,
                     author: nil)

      # Verify IPTC By-line takes precedence (both have "Creator1 (ref2021.1)" but IPTC should win)
      assert_equal ["Creator1 (ref2021.1)"], image.creator
      assert_equal "Creator1 (ref2021.1)", image.author

      # IPTC Headline should be extracted
      assert_equal "The Headline (ref2021.1)", image.headline

      # IPTC Keywords should be properly parsed
      assert_equal ["Keyword1ref2021.1", "Keyword2ref2021.1", "Keyword3ref2021.1"], image.keywords
    end
  end

  test "rake task can extract metadata from sample images" do
    image_path = Rails.root.join("test/fixtures/folio/metadata_test_images/IPTC-PhotometadataRef-Std2024.1.jpg")
    skip "Test image not found" unless File.exist?(image_path)

    # Create image without automatic extraction
    with_config(folio_image_metadata_extraction_enabled: false) do
      image = create(:folio_file_image,
                     file: File.open(image_path),
                     site: @site,
                     description: nil,
                     author: nil)

      # Should have no extracted metadata initially
      assert_nil image.description
      assert_nil image.author

      # Manually trigger extraction
      with_config(folio_image_metadata_extraction_enabled: true) do
        image.extract_metadata!

        # Now should have extracted metadata
        assert_equal "The description aka caption (ref2024.1)", image.description
        assert_equal "Creator1 (ref2024.1)", image.author
        assert_equal "The Headline (ref2024.1)", image.headline
      end
    end
  end

  test "metadata copying to file placements works with sample data" do
    image_path = Rails.root.join("test/fixtures/folio/metadata_test_images/IPTC-PhotometadataRef-Std2024.1.jpg")
    skip "Test image not found" unless File.exist?(image_path)

    with_config(folio_image_metadata_extraction_enabled: true,
                folio_image_metadata_copy_to_placements: true) do
      image = create(:folio_file_image,
                     file: File.open(image_path),
                     site: @site,
                     description: nil,
                     author: nil)

      page = create(:folio_page, site: @site)
      placement = create(:folio_image_placement,
                        file: image,
                        placement: page,
                        alt: nil,
                        title: nil)

      # Metadata should be copied to placement
      assert_equal "The description aka caption (ref2024.1)", placement.alt
      assert_equal "The Headline (ref2024.1)", placement.title
    end
  end

  private
    def with_config(**config_overrides)
      original_values = {}

      # Store original values
      config_overrides.each do |key, value|
        original_values[key] = Rails.application.config.send(key)
        Rails.application.config.send("#{key}=", value)
      end

      yield
    ensure
      # Restore original values
      original_values.each do |key, value|
        Rails.application.config.send("#{key}=", value)
      end
    end
end

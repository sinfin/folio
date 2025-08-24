# frozen_string_literal: true

require "test_helper"

class Folio::BackwardCompatibleIptcMetadataTest < ActiveSupport::TestCase
  def setup
    @site = get_any_site
  end

  test "author field backward compatibility - reading" do
    image = create(:folio_file_image, site: @site)

    # Test with new creator field
    image.update_column(:creator, ["John Doe", "Jane Smith"])
    assert_equal "John Doe", image.author

    # Test with legacy author_legacy field (if column exists)
    if image.has_attribute?(:author_legacy)
      image.update_columns(creator: [], author: nil)
      image.update_column(:author_legacy, "Legacy Author")
      assert_equal "Legacy Author", image.author
    end
  end

  test "author field backward compatibility - writing" do
    image = create(:folio_file_image, site: @site)

    # Setting author should update both new and legacy fields
    image.author = "Test Author"

    assert_equal "Test Author", image.author
    assert_equal ["Test Author"], image.creator

    # If we have the old author column, it should also be set
    if image.has_attribute?(:author) && image.respond_to?(:[]=)
      assert_equal "Test Author", image[:author]
    end
  end

  test "alt field backward compatibility - reading" do
    image = create(:folio_file_image, site: @site)

    # Test with new headline field
    image.update_column(:headline, "Test Headline")
    assert_equal "Test Headline", image.alt

    # Test with legacy alt_legacy field (if column exists)
    if image.has_attribute?(:alt_legacy)
      image.update_columns(headline: nil, alt: nil)
      image.update_column(:alt_legacy, "Legacy Alt")
      assert_equal "Legacy Alt", image.alt
    end
  end

  test "alt field backward compatibility - writing" do
    image = create(:folio_file_image, site: @site)

    # Setting alt should update both alt and headline
    image.alt = "Test Alt Text"

    assert_equal "Test Alt Text", image.alt
    # Headline should be set only if it was blank
    if image.headline.blank?
      assert_equal "Test Alt Text", image.headline
    end
  end

  test "legacy method aliases work correctly" do
    image = create(:folio_file_image, site: @site)

    image.author = "John Doe"

    # Legacy aliases should work
    assert_equal "John Doe", image.author_name
    assert_equal ["John Doe"], image.authors
  end

  test "keywords backward compatibility with tag_list" do
    image = create(:folio_file_image, site: @site)

    # Test setting via keywords_string
    image.keywords_string = "nature, landscape, photography"
    assert_equal ["nature", "landscape", "photography"], image.keywords
    assert_equal "nature, landscape, photography", image.keywords_string

    # Test tag_list alias (if not already defined by another module)
    if image.respond_to?(:tag_list) && !image.class.ancestors.any? { |a| a.name&.include?("Taggable") }
      image.tag_list = "test, sample"
      assert_equal ["test", "sample"], image.keywords
      assert_equal "test, sample", image.tag_list
    end
  end

  test "creator field normalization" do
    image = create(:folio_file_image, site: @site)

    # Array input
    image.creator = ["John", "Jane", "Bob"]
    assert_equal ["John", "Jane", "Bob"], image.creator
    assert_equal "John", image.author  # First creator becomes author

    # String input
    image.creator = "Single Author"
    assert_equal ["Single Author"], image.creator
    assert_equal "Single Author", image.author

    # Empty input
    image.creator = nil
    assert_equal [], image.creator

    # Blank strings should be filtered out
    image.creator = ["John", "", nil, "Jane", "   "]
    assert_equal ["John", "Jane"], image.creator
  end

  test "keywords field normalization" do
    image = create(:folio_file_image, site: @site)

    # Array input
    image.keywords = ["nature", "landscape"]
    assert_equal ["nature", "landscape"], image.keywords

    # String input (comma-separated)
    image.keywords = "city, night, lights"
    assert_equal ["city", "night", "lights"], image.keywords

    # String input (semicolon-separated)
    image.keywords = "red;green;blue"
    assert_equal ["red", "green", "blue"], image.keywords

    # Empty input
    image.keywords = nil
    assert_equal [], image.keywords

    # Blank strings should be filtered out
    image.keywords = ["valid", "", nil, "also valid", "   "]
    assert_equal ["valid", "also valid"], image.keywords
  end

  test "has_iptc_metadata_fields detection" do
    image = create(:folio_file_image, site: @site)

    # Should detect if new IPTC fields are available
    expected = image.has_attribute?(:creator) &&
              image.has_attribute?(:headline) &&
              image.has_attribute?(:keywords)

    assert_equal expected, image.has_iptc_metadata_fields?
  end

  test "needs_legacy_data_migration detection" do
    image = create(:folio_file_image, site: @site)

    # Skip test if no legacy columns exist
    return unless image.has_attribute?(:author_legacy) || image.has_attribute?(:alt_legacy)

    # Should not need migration if new fields have data
    image.update_columns(creator: ["Test"], headline: "Test")
    assert_not image.needs_legacy_data_migration?

    # Should need migration if legacy has data but new fields are empty
    if image.has_attribute?(:author_legacy)
      image.update_columns(creator: [], author_legacy: "Legacy Author")
      assert image.needs_legacy_data_migration?
    end

    if image.has_attribute?(:alt_legacy)
      image.update_columns(headline: nil, alt_legacy: "Legacy Alt")
      assert image.needs_legacy_data_migration?
    end
  end

  test "class methods for migration management" do
    # Skip if we don't have legacy columns
    return unless ActiveRecord::Base.connection.column_exists?(:folio_files, :author_legacy)

    # Test scopes work
    assert_respond_to Folio::File, :needing_legacy_migration
    assert_respond_to Folio::File, :legacy_migration_count

    # Should return numeric count
    count = Folio::File.legacy_migration_count
    assert count.is_a?(Integer)
    assert count >= 0
  end

  test "backward compatibility preserves existing behavior" do
    image = create(:folio_file_image, site: @site)

    # Standard ActiveRecord attribute assignment should work
    image.attributes = {
      "author" => "Assigned Author",
      "alt" => "Assigned Alt"
    }

    assert_equal "Assigned Author", image.author
    assert_equal "Assigned Alt", image.alt

    # Mass assignment should work
    image.update(author: "Updated Author", alt: "Updated Alt")

    assert_equal "Updated Author", image.author
    assert_equal "Updated Alt", image.alt
  end
end

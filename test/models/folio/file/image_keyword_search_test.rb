# frozen_string_literal: true

require "test_helper"

class Folio::File::ImageKeywordSearchTest < ActiveSupport::TestCase
  test "finds image by IPTC keyword" do
    match = create(:folio_file_image, file_metadata: { "keywords" => ["Pardubice", "město"] })
    no_match = create(:folio_file_image, file_metadata: { "keywords" => ["Praha"] })

    results = Folio::File::Image.by_query("Pardubice")
    assert_includes results, match
    assert_not_includes results, no_match
  end

  test "keyword search is case-insensitive" do
    image = create(:folio_file_image, file_metadata: { "keywords" => ["Pardubice"] })

    assert_includes Folio::File::Image.by_query("pardubice"), image
    assert_includes Folio::File::Image.by_query("PARDUBICE"), image
  end

  test "keyword search is accent-insensitive" do
    image = create(:folio_file_image, file_metadata: { "keywords" => ["Česká republika"] })

    assert_includes Folio::File::Image.by_query("Česká"), image
    assert_includes Folio::File::Image.by_query("Ceska"), image
  end

  test "keyword search uses prefix matching" do
    image = create(:folio_file_image, file_metadata: { "keywords" => ["Pardubice"] })

    assert_includes Folio::File::Image.by_query("Pardu"), image
    assert_not_includes Folio::File::Image.by_query("dubice"), image
  end

  test "searches file_name, headline, and description alongside keywords" do
    by_name = create(:folio_file_image, file_name: "pardubice.jpg", file_metadata: {})
    by_headline = create(:folio_file_image, headline: "Pardubice city", file_metadata: {})
    by_keyword = create(:folio_file_image, file_metadata: { "keywords" => ["Pardubice"] })

    results = Folio::File::Image.by_query("Pardubice")
    assert_includes results, by_name
    assert_includes results, by_headline
    assert_includes results, by_keyword
  end

  test "handles keywords stored as a string" do
    image = create(:folio_file_image, file_metadata: { "keywords" => "Pardubice, Praha" })

    assert_includes Folio::File::Image.by_query("Pardubice"), image
  end

  test "handles edge cases gracefully" do
    create(:folio_file_image, file_metadata: nil)
    create(:folio_file_image, file_metadata: { "keywords" => [] })

    assert_nothing_raised { Folio::File::Image.by_query("test").to_a }
    assert_equal 0, Folio::File::Image.by_query("").count
    assert_equal 0, Folio::File::Image.by_query(nil).count
  end

  test "returns distinct results on multiple matches" do
    image = create(:folio_file_image,
      file_name: "pardubice.jpg",
      headline: "Pardubice",
      file_metadata: { "keywords" => ["Pardubice"] }
    )

    assert_equal 1, Folio::File::Image.by_query("Pardubice").where(id: image.id).count
  end

  test "handles special characters without SQL injection" do
    assert_nothing_raised do
      Folio::File::Image.by_query("'; DROP TABLE folio_files; --").to_a
      Folio::File::Image.by_query("100%").to_a
    end
  end

  test "is chainable with other scopes" do
    match = create(:folio_file_image,
      file_metadata: { "keywords" => ["Pardubice"] },
      tag_list: ["architecture"]
    )
    no_match = create(:folio_file_image,
      file_metadata: { "keywords" => ["Pardubice"] },
      tag_list: ["nature"]
    )

    results = Folio::File::Image.by_query("Pardubice").by_tags("architecture")
    assert_includes results, match
    assert_not_includes results, no_match
  end

  test "works across file types" do
    image = create(:folio_file_image, file_metadata: { "keywords" => ["Pardubice"] })
    video = create(:folio_file_video, file_metadata: { "keywords" => ["Pardubice"] })

    results = Folio::File.by_query("Pardubice")
    assert_includes results, image
    assert_includes results, video
  end

  test "extracts keywords from IPTC XMP-dc:Subject field" do
    # Real IPTC metadata structure with XMP namespace
    image = create(:folio_file_image, file_metadata: {
      "XMP-dc:Subject" => ["Kroměříž", "město"]
    })

    # Keywords should be extracted and indexed
    assert_equal "Kroměříž město", image.keywords_for_search

    results = Folio::File::Image.by_query("Kroměříž")
    assert_includes results, image
  end

  test "extracts keywords from IPTC Keywords field" do
    # Real IPTC metadata structure with IPTC namespace
    image = create(:folio_file_image, file_metadata: {
      "IPTC:Keywords" => ["Pardubice", "Czech Republic"]
    })

    # Keywords should be extracted and indexed
    assert_equal "Pardubice Czech Republic", image.keywords_for_search

    results = Folio::File::Image.by_query("Pardubice")
    assert_includes results, image
  end

  test "prefers XMP-dc:Subject over IPTC:Keywords" do
    # When both are present, XMP should take precedence (per IptcFieldMapper)
    image = create(:folio_file_image, file_metadata: {
      "XMP-dc:Subject" => ["XMP keyword"],
      "IPTC:Keywords" => ["IPTC keyword"]
    })

    # Should use XMP-dc:Subject (first in FIELD_MAPPINGS priority)
    assert_equal "XMP keyword", image.keywords_for_search
  end
end
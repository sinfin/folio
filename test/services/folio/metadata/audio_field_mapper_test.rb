# frozen_string_literal: true

require "test_helper"

class Folio::Metadata::AudioFieldMapperTest < ActiveSupport::TestCase
  def setup
    @mapper = Folio::Metadata::AudioFieldMapper
  end

  test "maps all known fields from string-keyed metadata" do
    metadata = {
      "title" => "Ranní briefing",
      "artist" => "HN",
      "album" => "Podcasty",
      "track" => "7",
      "codec_name" => "mp3",
      "bitrate_kbps" => 128,
      "sample_rate_hz" => 44_100,
      "channels" => 2,
      "duration_seconds" => 849,
      "artwork_present" => true,
    }

    result = @mapper.map_metadata(metadata)

    assert_equal "Ranní briefing", result[:title]
    assert_equal "HN", result[:artist]
    assert_equal "Podcasty", result[:album]
    assert_equal "7", result[:track]
    assert_equal "mp3", result[:codec_name]
    assert_equal 128, result[:bitrate_kbps]
    assert_equal 44_100, result[:sample_rate_hz]
    assert_equal 2, result[:channels]
    assert_equal 849, result[:duration_seconds]
    assert_equal true, result[:artwork_present]
  end

  test "excludes nil values from result" do
    metadata = {
      "title" => "Ranní briefing",
      "artist" => nil,
    }

    result = @mapper.map_metadata(metadata)

    assert_equal "Ranní briefing", result[:title]
    assert_not result.key?(:artist)
  end

  test "returns empty hash for empty metadata" do
    result = @mapper.map_metadata({})

    assert result.is_a?(Hash)
    assert result.empty?
  end

  test "ignores unknown keys" do
    result = @mapper.map_metadata({ "unknown_field" => "value" })

    assert result.is_a?(Hash)
    assert result.empty?
  end

  test "update_database_fields writes artist to author when author is blank" do
    audio = create(:folio_file_audio, author: nil)
    mapped = { artist: "Test Artist", title: "Test Title" }

    @mapper.update_database_fields(audio, mapped)

    assert_equal "Test Artist", audio.reload.author
  end

  test "update_database_fields writes title to headline when headline is blank" do
    audio = create(:folio_file_audio, headline: nil)
    mapped = { artist: "Test Artist", title: "Test Title" }

    @mapper.update_database_fields(audio, mapped)

    assert_equal "Test Title", audio.reload.headline
  end

  test "update_database_fields does not overwrite existing author" do
    audio = create(:folio_file_audio, author: "Existing Author")
    mapped = { artist: "New Artist" }

    @mapper.update_database_fields(audio, mapped)

    assert_equal "Existing Author", audio.reload.author
  end

  test "update_database_fields does not overwrite existing headline" do
    audio = create(:folio_file_audio, headline: "Existing Headline")
    mapped = { title: "New Title" }

    @mapper.update_database_fields(audio, mapped)

    assert_equal "Existing Headline", audio.reload.headline
  end

  test "update_database_fields skips blank mapped values" do
    audio = create(:folio_file_audio, author: nil)
    mapped = { artist: "" }

    @mapper.update_database_fields(audio, mapped)

    assert_nil audio.reload.author
  end
end

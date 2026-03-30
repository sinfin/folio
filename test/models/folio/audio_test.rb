# frozen_string_literal: true

require "test_helper"

class Folio::File::AudioTest < ActiveSupport::TestCase
  test "audio files are private" do
    audio = build(:folio_file_audio)

    assert_predicate audio, :private?
  end

  test "mapped metadata exposes normalized audio fields" do
    audio = create(:folio_file_audio)
    audio.update!(
      file_metadata: {
        "title" => "Ranni briefing",
        "artist" => "HN",
        "album" => "Podcasty",
        "track" => "7",
        "bitrate_kbps" => 128,
        "sample_rate_hz" => 44_100,
        "channels" => 1,
        "codec_name" => "mp3",
        "artwork_present" => true,
      }
    )

    metadata = audio.mapped_metadata

    assert_equal "Ranni briefing", metadata[:title]
    assert_equal "HN", metadata[:artist]
    assert_equal 128, metadata[:bitrate_kbps]
    assert_equal true, metadata[:artwork_present]
    assert_nil metadata[:missing_key]
  end

  test "playable download url presigns encoded derivative from s3 path" do
    audio = create(:folio_file_audio,
                   remote_services_data: {
                     "playable" => {
                       "storage" => "s3",
                       "path" => "test/audio/encoded/file.mp3",
                       "extension" => "mp3",
                       "content_type" => "audio/mpeg",
                     }
                   })

    audio.stub(:test_aware_presign_url, "https://signed.example.test/file.mp3") do
      assert_equal "https://signed.example.test/file.mp3", audio.playable_download_url
      assert_equal "audio/mpeg", audio.playable_content_type
      assert_equal "mp3", audio.playable_extension
    end
  end

  test "artwork image placement wraps derived image" do
    artwork = create(:folio_file_image)
    audio = create(:folio_file_audio, remote_services_data: { "artwork_image_id" => artwork.id })

    placement = audio.artwork_image_placement

    assert_instance_of Folio::FilePlacement::Cover, placement
    assert_equal artwork, placement.file
  end
end

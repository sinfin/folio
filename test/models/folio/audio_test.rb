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

    assert_equal "Ranni briefing", audio.mapped_metadata[:title]
    assert_equal "HN", audio.mapped_metadata[:artist]
    assert_equal 128, audio.mapped_metadata[:bitrate_kbps]
    assert_equal true, audio.mapped_metadata[:artwork_present]
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

    audio.stubs(:test_aware_presign_url).with(s3_path: "test/audio/encoded/file.mp3", method_name: :get_object).returns("https://signed.example.test/file.mp3")

    assert_equal "https://signed.example.test/file.mp3", audio.playable_download_url
    assert_equal "audio/mpeg", audio.playable_content_type
    assert_equal "mp3", audio.playable_extension
  end

  test "artwork image placement wraps derived image" do
    artwork = create(:folio_file_image)
    audio = create(:folio_file_audio, remote_services_data: { "artwork_image_id" => artwork.id })

    placement = audio.artwork_image_placement

    assert_instance_of Folio::FilePlacement::Cover, placement
    assert_equal artwork, placement.file
  end
end

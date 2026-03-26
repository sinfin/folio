# frozen_string_literal: true

require "test_helper"

class Folio::File::AudioProcessingServiceTest < ActiveSupport::TestCase
  test "extract_metadata maps audio stream and tags" do
    audio = create(:folio_file_audio)
    service = Folio::File::AudioProcessingService.new(audio)

    service.stubs(:inspect_media).returns({
      "format" => {
        "duration" => "849.2",
        "bit_rate" => "128000",
        "tags" => {
          "title" => "Ranni briefing",
          "artist" => "HN",
          "album" => "Podcasty",
          "track" => "12",
        },
      },
      "streams" => [
        {
          "codec_type" => "audio",
          "codec_name" => "mp3",
          "sample_rate" => "44100",
          "channels" => 1,
        },
        {
          "codec_type" => "video",
          "codec_name" => "mjpeg",
          "disposition" => { "attached_pic" => 1 },
        }
      ]
    })

    metadata = service.extract_metadata!(force: true, save: false)

    assert_equal "Ranni briefing", metadata["title"]
    assert_equal "HN", metadata["artist"]
    assert_equal "Podcasty", metadata["album"]
    assert_equal 128, metadata["bitrate_kbps"]
    assert_equal 44_100, metadata["sample_rate_hz"]
    assert_equal 1, metadata["channels"]
    assert_equal true, metadata["artwork_present"]
    assert_equal 850, metadata["duration_seconds"]
  end

  test "call persists playable derivative and derived artwork image" do
    audio = create(:folio_file_audio)
    service = Folio::File::AudioProcessingService.new(audio)
    artwork = create(:folio_file_image)

    service.stubs(:inspect_media).returns({
      "format" => {
        "duration" => "120",
        "bit_rate" => "128000",
        "tags" => {},
      },
      "streams" => [
        {
          "codec_type" => "audio",
          "codec_name" => "mp3",
          "sample_rate" => "44100",
          "channels" => 1,
        }
      ]
    })
    service.stubs(:create_playable_derivative).returns({
      "storage" => "local",
      "path" => "/tmp/audio.mp3",
      "extension" => "mp3",
      "content_type" => "audio/mpeg",
    })
    service.stubs(:create_or_update_artwork_image).returns(artwork)

    service.call

    assert_equal "ready", audio.reload.aasm_state
    assert_equal "/tmp/audio.mp3", audio.remote_services_data["playable"]["path"]
    assert_equal artwork.id, audio.remote_services_data["artwork_image_id"]
    assert audio.file_metadata_extracted_at.present?
  end
end

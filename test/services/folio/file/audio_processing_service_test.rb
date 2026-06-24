# frozen_string_literal: true

require "test_helper"

class Folio::File::AudioProcessingServiceTest < ActiveSupport::TestCase
  test "extract_metadata maps audio stream and tags" do
    audio = create(:folio_file_audio)
    service = Folio::File::AudioProcessingService.new(audio)

    inspect_media_result = {
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
    }

    service.stub(:inspect_media, inspect_media_result) do
      metadata = service.extract_metadata!(force: true, save: false)

      assert_equal "Ranni briefing", metadata["title"]
      assert_equal "HN", metadata["artist"]
      assert_equal "Podcasty", metadata["album"]
      assert_equal 128, metadata["bitrate_kbps"]
      assert_equal 44_100, metadata["sample_rate_hz"]
      assert_equal 1, metadata["channels"]
      assert_equal true, metadata["artwork_present"]
      assert_equal 849, metadata["duration_seconds"]
    end
  end

  test "call persists playable derivative and derived artwork image" do
    audio = create(:folio_file_audio)
    service = Folio::File::AudioProcessingService.new(audio)
    artwork = create(:folio_file_image)

    inspect_media_result = {
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
    }

    playable_result = {
      "storage" => "s3",
      "path" => "audio/encoded/1/1/audio-playable.mp3",
      "extension" => "mp3",
      "content_type" => "audio/mpeg",
    }

    service.stub(:inspect_media, inspect_media_result) do
      service.stub(:create_playable_derivative, playable_result) do
        service.stub(:create_or_update_artwork_image, artwork) do
          service.call
        end
      end
    end

    assert_equal "ready", audio.reload.aasm_state
    assert_equal "audio/encoded/1/1/audio-playable.mp3", audio.remote_services_data["playable"]["path"]
    assert_equal artwork.id, audio.remote_services_data["artwork_image_id"]
    assert audio.file_metadata_extracted_at.present?
  end

  test "call keeps old playable derivative when new derivative upload fails" do
    old_path = "audio/encoded/1/1/old-playable.mp3"
    audio = create(:folio_file_audio,
                   remote_services_data: {
                     "playable" => {
                       "storage" => "s3",
                       "path" => old_path,
                       "extension" => "mp3",
                       "content_type" => "audio/mpeg",
                     }
                   })
    service = Folio::File::AudioProcessingService.new(audio)
    inspect_media_result = {
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
    }
    delete_calls = []

    service.stub(:inspect_media, inspect_media_result) do
      service.stub(:shell, "") do
        service.stub(:test_aware_s3_delete, -> (s3_path:) { delete_calls << s3_path }) do
          service.stub(:test_aware_s3_upload, -> (**_kwargs) { raise "upload failed" }) do
            assert_raises(RuntimeError) { service.call }
          end
        end
      end
    end

    assert_empty delete_calls
    assert_equal old_path, audio.reload.playable_file_path
  end

  test "call deletes old playable derivative after new derivative is persisted" do
    old_path = "audio/encoded/1/1/old-playable.mp3"
    audio = create(:folio_file_audio,
                   remote_services_data: {
                     "playable" => {
                       "storage" => "s3",
                       "path" => old_path,
                       "extension" => "mp3",
                       "content_type" => "audio/mpeg",
                     }
                   })
    service = Folio::File::AudioProcessingService.new(audio)
    inspect_media_result = {
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
    }
    delete_calls = []

    service.stub(:inspect_media, inspect_media_result) do
      service.stub(:shell, "") do
        service.stub(:test_aware_s3_upload, nil) do
          service.stub(:test_aware_s3_delete, lambda { |s3_path:|
            delete_calls << s3_path
            assert_not_equal old_path, audio.reload.playable_file_path
          }) do
            service.call
          end
        end
      end
    end

    assert_equal [old_path], delete_calls
  end
end

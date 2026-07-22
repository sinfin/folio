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

  test "call persists playable derivative" do
    audio = create(:folio_file_audio)
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

    playable_result = {
      "storage" => "s3",
      "path" => "audio/encoded/1/1/audio-playable.mp3",
      "extension" => "mp3",
      "content_type" => "audio/mpeg",
    }

    service.stub(:inspect_media, inspect_media_result) do
      service.stub(:create_playable_derivative, playable_result) do
        service.call
      end
    end

    assert_equal "ready", audio.reload.aasm_state
    assert_equal "audio/encoded/1/1/audio-playable.mp3", audio.remote_services_data["playable"]["path"]
    assert audio.file_metadata_extracted_at.present?
    assert audio.remote_services_data["artwork_seeded_at"].present?
  end

  test "call persists waveform generated from playable derivative" do
    audio = create(:folio_file_audio)
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

    playable_result = {
      "storage" => "s3",
      "path" => "audio/encoded/1/1/audio-playable.mp3",
      "extension" => "mp3",
      "content_type" => "audio/mpeg",
    }

    waveform_result = {
      "peaks" => [0.0, 0.25, 1.0],
    }

    service.stub(:inspect_media, inspect_media_result) do
      service.stub(:create_playable_derivative, playable_result) do
        service.stub(:generate_waveform_payload, waveform_result) do
          service.call
        end
      end
    end

    waveform = audio.reload.remote_services_data["waveform"]

    assert_equal [0.0, 0.25, 1.0], waveform["peaks"]
  end

  test "call persists normalized fixed-count waveform peaks from decoded playable audio" do
    audio = create(:folio_file_audio)
    service = Folio::File::AudioProcessingService.new(audio)

    inspect_media_result = {
      "format" => {
        "duration" => "222",
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
      "storage" => "local",
      "path" => "audio/encoded/1/1/audio-playable.mp3",
      "extension" => "mp3",
      "content_type" => "audio/mpeg",
    }

    shell = lambda do |*args|
      output_path = args.last
      samples = [0, 16, 32, 64] * 13
      File.binwrite(output_path, samples.pack("s<*"))
      ""
    end

    service.stub(:inspect_media, inspect_media_result) do
      service.stub(:create_playable_derivative, playable_result) do
        service.stub(:shell, shell) do
          service.call
        end
      end
    end

    waveform = audio.reload.remote_services_data["waveform"]

    assert_equal 200, waveform["peaks"].size
    assert_equal 1.0, waveform["peaks"].max
  end

  test "call keeps audio playable when waveform generation fails" do
    audio = create(:folio_file_audio)
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

    playable_result = {
      "storage" => "s3",
      "path" => "audio/encoded/1/1/audio-playable.mp3",
      "extension" => "mp3",
      "content_type" => "audio/mpeg",
    }

    service.stub(:inspect_media, inspect_media_result) do
      service.stub(:create_playable_derivative, playable_result) do
        service.stub(:generate_waveform_payload, -> (*) { raise "waveform failed" }) do
          service.call
        end
      end
    end

    audio.reload

    assert_equal "ready", audio.aasm_state
    assert_equal "audio/encoded/1/1/audio-playable.mp3", audio.remote_services_data["playable"]["path"]
    assert_nil audio.remote_services_data["waveform"]
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

  test "call seeds artwork cover from embedded artwork on first processing only" do
    audio = create(:folio_file_audio)
    service = Folio::File::AudioProcessingService.new(audio)

    inspect_media_result = {
      "format" => { "duration" => "120", "bit_rate" => "128000", "tags" => {} },
      "streams" => [
        { "codec_type" => "audio", "codec_name" => "mp3", "sample_rate" => "44100", "channels" => 1 },
        { "codec_type" => "video", "codec_name" => "mjpeg", "disposition" => { "attached_pic" => 1 } }
      ]
    }

    playable_result = {
      "storage" => "s3",
      "path" => "audio/encoded/1/1/audio-playable.mp3",
      "extension" => "mp3",
      "content_type" => "audio/mpeg",
    }

    write_fixture_artwork = -> (*args) do
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), args.last)
      ""
    end

    run_processing = -> do
      service.stub(:inspect_media, inspect_media_result) do
        service.stub(:create_playable_derivative, playable_result) do
          service.stub(:safely_generate_waveform_payload, nil) do
            service.stub(:shell, write_fixture_artwork) do
              service.call
            end
          end
        end
      end
    end

    run_processing.call
    audio.reload

    seeded = audio.artwork_cover
    assert seeded.present?
    assert_instance_of Folio::FilePlacement::ArtworkCover, audio.artwork_cover_placement

    # a reprocess keeps the seeded artwork untouched
    run_processing.call
    assert_equal seeded, audio.reload.artwork_cover

    # a removed artwork stays removed on reprocess — the console owns it
    audio.artwork_cover_placement.destroy!
    run_processing.call
    assert_nil audio.reload.artwork_cover
  end

  test "call seeds artwork on retry after a failed first processing" do
    audio = create(:folio_file_audio)
    # the processing job stamps processed_at and the error into remote data
    # on failure — that must not block artwork seeding on a successful retry
    audio.update_columns(remote_services_data: { "error" => "boom", "processed_at" => Time.current.iso8601 })
    service = Folio::File::AudioProcessingService.new(audio)

    inspect_media_result = {
      "format" => { "duration" => "120", "bit_rate" => "128000", "tags" => {} },
      "streams" => [
        { "codec_type" => "audio", "codec_name" => "mp3", "sample_rate" => "44100", "channels" => 1 },
        { "codec_type" => "video", "codec_name" => "mjpeg", "disposition" => { "attached_pic" => 1 } }
      ]
    }

    playable_result = {
      "storage" => "s3",
      "path" => "audio/encoded/1/1/audio-playable.mp3",
      "extension" => "mp3",
      "content_type" => "audio/mpeg",
    }

    write_fixture_artwork = -> (*args) do
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), args.last)
      ""
    end

    service.stub(:inspect_media, inspect_media_result) do
      service.stub(:create_playable_derivative, playable_result) do
        service.stub(:safely_generate_waveform_payload, nil) do
          service.stub(:shell, write_fixture_artwork) do
            service.call
          end
        end
      end
    end

    assert audio.reload.artwork_cover.present?
    assert audio.remote_services_data["artwork_seeded_at"].present?
  end

  test "call retries artwork seeding after extraction failure" do
    audio = create(:folio_file_audio)
    service = Folio::File::AudioProcessingService.new(audio)

    inspect_media_result = {
      "format" => { "duration" => "120", "bit_rate" => "128000", "tags" => {} },
      "streams" => [
        { "codec_type" => "audio", "codec_name" => "mp3", "sample_rate" => "44100", "channels" => 1 },
        { "codec_type" => "video", "codec_name" => "mjpeg", "disposition" => { "attached_pic" => 1 } }
      ]
    }

    playable_result = {
      "storage" => "s3",
      "path" => "audio/encoded/1/1/audio-playable.mp3",
      "extension" => "mp3",
      "content_type" => "audio/mpeg",
    }

    run_processing = lambda do |shell|
      service.stub(:inspect_media, inspect_media_result) do
        service.stub(:create_playable_derivative, playable_result) do
          service.stub(:safely_generate_waveform_payload, nil) do
            service.stub(:shell, shell) do
              service.call
            end
          end
        end
      end
    end

    run_processing.call(-> (*) { raise "artwork failed" })
    audio.reload

    assert_equal "ready", audio.aasm_state
    assert_nil audio.artwork_cover
    assert_nil audio.remote_services_data["artwork_seeded_at"]

    write_fixture_artwork = -> (*args) do
      FileUtils.cp(Folio::Engine.root.join("test/fixtures/folio/test.gif"), args.last)
      ""
    end

    run_processing.call(write_fixture_artwork)

    assert audio.reload.artwork_cover.present?
    assert audio.remote_services_data["artwork_seeded_at"].present?
  end
end

# frozen_string_literal: true

require "test_helper"

class Folio::File::AudioTest < ActiveSupport::TestCase
  test "audio files are public by default" do
    audio = build(:folio_file_audio)

    assert_not_predicate audio, :private?
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

  test "playable download url passes expires_in to presign" do
    audio = create(:folio_file_audio,
                   remote_services_data: {
                     "playable" => {
                       "storage" => "s3",
                       "path" => "test/audio/encoded/file.mp3",
                       "extension" => "mp3",
                       "content_type" => "audio/mpeg",
                     }
                   })
    passed_expires_in = nil
    presigner = -> (s3_path:, method_name:, expires_in: nil) do
      assert_equal "test/audio/encoded/file.mp3", s3_path
      assert_equal :get_object, method_name
      passed_expires_in = expires_in
      "https://signed.example.test/file.mp3"
    end

    audio.stub(:test_aware_presign_url, presigner) do
      assert_equal "https://signed.example.test/file.mp3", audio.playable_download_url(expires_in: 1.hour.to_i)
    end

    assert_equal 1.hour.to_i, passed_expires_in
  end

  test "player source url falls back to public cdn original for public audio" do
    audio = create(:folio_file_audio)
    cdn_url = "https://cdn.example.test/audio.mp3"

    Folio::S3.stub(:cdn_url_rewrite, cdn_url) do
      assert_equal cdn_url, audio.player_source_url
    end
  end

  test "player source url signs original fallback for private audio" do
    audio = create(:folio_file_audio)
    signed_url = "https://signed.example.test/audio.mp3"
    signed_calls = 0

    audio.stub(:private?, true) do
      Folio::S3.stub(:cdn_url_rewrite, -> (*) { flunk "private audio must not use public cdn fallback" }) do
        Folio::S3.stub(:url_rewrite, lambda { |_|
          signed_calls += 1
          signed_url
        }) do
          assert_equal signed_url, audio.player_source_url(expires_in: 1.hour.to_i)
        end
      end
    end

    assert_equal 1, signed_calls
  end

  test "cacheable source payload uses public original even when playable derivative exists" do
    audio = create(:folio_file_audio,
                   file_mime_type: "audio/wav",
                   remote_services_data: {
                     "playable" => {
                       "storage" => "s3",
                       "path" => "test/audio/encoded/file.mp3",
                       "extension" => "mp3",
                       "content_type" => "audio/mpeg",
                     }
                   })
    cdn_url = "https://cdn.example.test/audio.wav"

    audio.stub(:playable_download_url, -> (*) { flunk "cacheable payload must not presign playable audio" }) do
      Folio::S3.stub(:cdn_url_rewrite, cdn_url) do
        assert_equal({
          url: cdn_url,
          mime_type: "audio/wav",
          cacheable: true,
        }, audio.source_payload(intent: :cacheable))
      end
    end
  end

  test "immediate source payload uses playable derivative with matching mime type" do
    audio = create(:folio_file_audio,
                   file_mime_type: "audio/wav",
                   remote_services_data: {
                     "playable" => {
                       "storage" => "s3",
                       "path" => "test/audio/encoded/file.mp3",
                       "extension" => "mp3",
                       "content_type" => "audio/mpeg",
                     }
                   })
    signed_url = "https://signed.example.test/file.mp3"

    audio.stub(:playable_download_url, signed_url) do
      assert_equal({
        url: signed_url,
        mime_type: "audio/mpeg",
        cacheable: false,
      }, audio.source_payload(intent: :immediate_playback))
    end
  end

  test "cacheable source payload omits private audio url" do
    audio = create(:folio_file_audio)

    audio.stub(:private?, true) do
      Folio::S3.stub(:cdn_url_rewrite, -> (*) { flunk "private audio cacheable payload must not use CDN" }) do
        assert_equal({
          url: nil,
          mime_type: audio.file_mime_type,
          cacheable: false,
        }, audio.source_payload(intent: :cacheable))
      end
    end
  end

  test "formatted_duration returns nil when file_track_duration is nil" do
    audio = build(:folio_file_audio, file_track_duration: nil)
    assert_nil audio.formatted_duration
  end

  test "formatted_duration returns M:SS for durations under one hour" do
    audio = build(:folio_file_audio)

    audio.file_track_duration = 0
    assert_equal "0:00", audio.formatted_duration

    audio.file_track_duration = 35
    assert_equal "0:35", audio.formatted_duration

    audio.file_track_duration = 90
    assert_equal "1:30", audio.formatted_duration

    audio.file_track_duration = 3599
    assert_equal "59:59", audio.formatted_duration
  end

  test "formatted_duration returns H:MM:SS for durations of one hour or more" do
    audio = build(:folio_file_audio)

    audio.file_track_duration = 3600
    assert_equal "1:00:00", audio.formatted_duration

    audio.file_track_duration = 7384
    assert_equal "2:03:04", audio.formatted_duration
  end

  test "artwork image placement wraps derived image" do
    artwork = create(:folio_file_image)
    audio = create(:folio_file_audio, remote_services_data: { "artwork_image_id" => artwork.id })

    placement = audio.artwork_image_placement

    assert_instance_of Folio::FilePlacement::Cover, placement
    assert_equal artwork, placement.file
  end

  test "artwork image memoizes missing derived image" do
    audio = create(:folio_file_audio, remote_services_data: { "artwork_image_id" => -1 })
    find_calls = 0
    missing_image_lookup = -> (*, **) do
      find_calls += 1
      nil
    end

    Folio::File::Image.stub(:find_by, missing_image_lookup) do
      2.times { assert_nil audio.artwork_image }
    end

    assert_equal 1, find_calls
  end
end

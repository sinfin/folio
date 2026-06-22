# frozen_string_literal: true

require "test_helper"

class Folio::FileSerializerTest < ActiveSupport::TestCase
  test "audio without playable derivative falls back to original source url" do
    audio = create(:folio_file_audio)

    data = Folio::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)

    assert data[:source_url].present?
    assert_equal audio.file_mime_type, data[:player_source_mime_type]
  end

  test "audio uses playable download url as source url" do
    audio = create(:folio_file_audio)
    playable_url = "https://media.example.com/audio/playable.mp3"

    data = audio.stub(:playable_download_url, playable_url) do
      Folio::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)
    end

    assert_equal playable_url, data[:source_url]
  end

  test "private audio uses player source url without public cdn fallback" do
    audio = create(:folio_file_audio)
    signed_url = "https://signed.example.com/audio/playable.mp3"

    data = audio.stub(:private?, true) do
      audio.stub(:player_source_url, signed_url) do
        Folio::S3.stub(:cdn_url_rewrite, -> (*) { flunk "private audio must not use public cdn fallback" }) do
          Folio::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)
        end
      end
    end

    assert_equal signed_url, data[:source_url]
  end

  test "audio uses playable content type for player source mime type" do
    audio = create(:folio_file_audio)
    audio.update_columns(
      file_mime_type: "audio/wav",
      remote_services_data: {
        "playable" => {
          "storage" => "s3",
          "path" => "audio/encoded/1/1/audio-playable.mp3",
          "extension" => "mp3",
          "content_type" => "audio/mpeg",
        }
      }
    )

    data = audio.stub(:playable_download_url, "https://media.example.com/audio/playable.mp3") do
      Folio::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)
    end

    assert_equal "audio/mpeg", data[:player_source_mime_type]
  end
end

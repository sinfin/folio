# frozen_string_literal: true

require "test_helper"

class Folio::Console::FileSerializerTest < ActiveSupport::TestCase
  test "audio without playable derivative falls back to original source url" do
    audio = create(:folio_file_audio)

    data = Folio::Console::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)

    assert data[:source_url].present?
    assert_equal audio.file_mime_type, data[:player_source_mime_type]
  end

  test "audio uses playable download url as source url" do
    audio = create(:folio_file_audio,
                   file_mime_type: "audio/wav",
                   remote_services_data: {
                     "playable" => {
                       "storage" => "s3",
                       "path" => "audio/encoded/1/1/audio-playable.mp3",
                       "extension" => "mp3",
                       "content_type" => "audio/mpeg",
                     }
                   })
    playable_url = "https://media.example.com/audio/playable.mp3"

    data = audio.stub(:playable_download_url, playable_url) do
      Folio::Console::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)
    end

    assert_equal playable_url, data[:source_url]
    assert_equal "audio/mpeg", data[:player_source_mime_type]
  end

  test "audio source url and player source mime type come from the same immediate payload" do
    audio = create(:folio_file_audio)
    payload = { url: "https://signed.example.com/audio.mp3", mime_type: "audio/mpeg", cacheable: false }

    data = audio.stub(:source_payload, payload) do
      Folio::Console::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)
    end

    assert_equal "https://signed.example.com/audio.mp3", data[:source_url]
    assert_equal "audio/mpeg", data[:player_source_mime_type]
  end

  test "private audio uses player source url without public cdn fallback" do
    audio = create(:folio_file_audio)
    signed_url = "https://signed.example.com/audio/playable.mp3"

    data = audio.stub(:private?, true) do
      Folio::S3.stub(:cdn_url_rewrite, -> (*) { flunk "private audio must not use public cdn fallback" }) do
        Folio::S3.stub(:url_rewrite, signed_url) do
          Folio::Console::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)
        end
      end
    end

    assert_equal signed_url, data[:source_url]
  end

  test "non-private file uses cdn url as source_url and file_mime_type for player_source_mime_type" do
    image = create(:folio_file_image)
    cdn_url = "https://cdn.example.com/image.jpg"

    Folio::S3.stub(:cdn_url_rewrite, cdn_url) do
      data = Folio::Console::FileSerializer.new(image).serializable_hash.dig(:data, :attributes)

      assert_equal cdn_url, data[:source_url]
      assert_equal image.file_mime_type, data[:player_source_mime_type]
    end
  end
end

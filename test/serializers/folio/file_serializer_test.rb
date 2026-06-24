# frozen_string_literal: true

require "test_helper"

class Folio::FileSerializerTest < ActiveSupport::TestCase
  test "audio without playable derivative falls back to original source url" do
    audio = create(:folio_file_audio)

    data = Folio::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)

    assert data[:source_url].present?
    assert_equal audio.file_mime_type, data[:player_source_mime_type]
  end

  test "audio with playable derivative uses cacheable original source url" do
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
    cdn_url = "https://cdn.example.com/audio.wav"

    data = audio.stub(:playable_download_url, -> (*) { flunk "public serializer must not presign playable audio" }) do
      Folio::S3.stub(:cdn_url_rewrite, cdn_url) do
        Folio::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)
      end
    end

    assert_equal cdn_url, data[:source_url]
    assert_equal "audio/wav", data[:player_source_mime_type]
  end

  test "private audio omits source url in public serializer" do
    audio = create(:folio_file_audio)

    data = audio.stub(:private?, true) do
      Folio::S3.stub(:cdn_url_rewrite, -> (*) { flunk "private audio must not use public cdn fallback" }) do
        Folio::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)
      end
    end

    assert_nil data[:source_url]
    assert_equal audio.file_mime_type, data[:player_source_mime_type]
  end

  test "audio source url and player source mime type come from the same cacheable payload" do
    audio = create(:folio_file_audio)
    payload = { url: "https://cdn.example.com/audio.ogg", mime_type: "audio/ogg", cacheable: true }

    data = audio.stub(:source_payload, payload) do
      Folio::FileSerializer.new(audio).serializable_hash.dig(:data, :attributes)
    end

    assert_equal "https://cdn.example.com/audio.ogg", data[:source_url]
    assert_equal "audio/ogg", data[:player_source_mime_type]
  end
end

# frozen_string_literal: true

require "test_helper"

class Folio::FileSerializerTest < ActiveSupport::TestCase
  test "private audio uses playable content type for player source mime type" do
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

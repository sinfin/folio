# frozen_string_literal: true

class Folio::OpenAi::TranscribeSubtitlesJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError

  queue_as :default

  def perform(video_file, lang = "cs")
    raise "only video files can be transcribed" unless video_file.is_a?(Folio::File::Video)

    # compress audio into a small, speech-optimized .ogg file using the Opus codec
    audio_tempfile = Tempfile.new(["audio", ".ogg"], binmode: true)
    extract_and_compress_audio(video_file.file.remote_url, audio_tempfile.path)

    # transcribe audio using OpenAI Whisper API
    subtitles = whisper_api_request(audio_tempfile, lang)

    # save subtitles without VTT header for easier editing
    video_file.set_subtitles(lang, subtitles.delete_prefix("WEBVTT\n\n"))
    video_file.save!
  ensure
    audio_tempfile.close
    audio_tempfile.unlink
  end

  private
    def extract_and_compress_audio(video_file_path, audio_file_path)
      system("ffmpeg -y -i #{video_file_path} -hide_banner -loglevel error -vn -map_metadata -1 -ac 1 -c:a libopus -b:a 12k -application voip #{audio_file_path}")
    end

    def whisper_api_request(file, lang)
      uri = URI("https://api.openai.com/v1/audio/transcriptions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 5 * 60
      http.open_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{ENV.fetch("OPENAI_API_KEY")}"

      form_data = [
        ["file", file],
        ["model", "whisper-1"],
        ["response_format", "vtt"],
        ["language", lang]
      ]
      request.set_form form_data, "multipart/form-data"

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Whisper API error: #{response.code} / #{JSON.parse(response.body).dig("error", "message")}"
      end

      response.body
    end
end

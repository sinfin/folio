# frozen_string_literal: true

class Folio::OpenAi::TranscribeSubtitlesJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError

  queue_as :default

  def perform(video_file)
    raise "only video files can be transcribed" unless video_file.is_a?(Folio::File::Video)

    begin
      # Mark transcription as started in video metadata
      mark_transcription_started!(video_file)

      # Use OpenAI's language detection or fallback to site preference
      lang = determine_target_language(video_file)

      subtitle = video_file.subtitle_for!(lang)
      audio_tempfile = nil
      # compress audio into a small, speech-optimized .ogg file using the Opus codec
      audio_tempfile = Tempfile.new(["audio", ".ogg"], binmode: true)

      # Get the cloud storage URL (using expiring URL for security)
      cloud_storage_url = generate_expiring_s3_url(video_file)
      extract_and_compress_audio(cloud_storage_url, audio_tempfile.path)

      # transcribe audio using OpenAI Whisper API
      subtitles = whisper_api_request(audio_tempfile, lang)

      # save subtitles without VTT header for easier editing
      vtt_content = subtitles.delete_prefix("WEBVTT\n\n")
      subtitle.mark_transcription_ready!(vtt_content)

      if subtitle.enabled?
        Rails.logger.info "[OpenAi::TranscribeSubtitlesJob] Transcription completed successfully and enabled for video_file ID: #{video_file.id}"
      else
        Rails.logger.warn "[OpenAi::TranscribeSubtitlesJob] Transcription completed but subtitles are invalid and kept disabled for video_file ID: #{video_file.id}"
      end

      # Mark transcription as completed
      mark_transcription_completed!(video_file)

    rescue => e
      # Mark transcription as failed in video metadata
      mark_transcription_failed!(video_file, e.message)

      if defined?(subtitle) && subtitle
        subtitle.mark_transcription_failed!(e.message)
      end

      Sentry.capture_exception(e) if defined?(Sentry)
    ensure
      if audio_tempfile
        audio_tempfile.close
        audio_tempfile.unlink
      end

      broadcast_file_update(video_file)
      broadcast_subtitles_update(video_file)
    end
  end

  private
    def extract_and_compress_audio(video_file_path, audio_file_path)
      system("ffmpeg -y -i #{video_file_path} -loglevel error -vn -map_metadata -1 -ac 1 -c:a libopus -b:a 12k -application voip #{audio_file_path}")
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
        ["language", lang.to_s]
      ]
      request.set_form form_data, "multipart/form-data"

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Whisper API error: #{response.code} / #{JSON.parse(response.body).dig("error", "message")}"
      end

      response.body
    end

    def save_subtitles!(video_file)
      video_file.update_columns(additional_data: video_file.additional_data,
                                updated_at: Time.current)
      broadcast_file_update(video_file)
      broadcast_subtitles_update(video_file)
    end

    def broadcast_subtitles_update(video_file)
      return if message_bus_user_ids.blank?

      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                         {
                           type: "Folio::OpenAi::TranscribeSubtitlesJob/updated",
                           data: { id: video_file.id },
                         }.to_json,
                         user_ids: message_bus_user_ids
    end

    def mark_transcription_started!(video_file)
      additional_data = video_file.additional_data || {}
      additional_data["subtitle_transcription"] = {
        "status" => "processing",
        "job_class" => self.class.name,
        "started_at" => Time.current.iso8601,
        "job_id" => job_id
      }
      video_file.update_column(:additional_data, additional_data)
      broadcast_file_update(video_file)
      broadcast_subtitles_update(video_file)
    end

    def mark_transcription_completed!(video_file)
      additional_data = video_file.additional_data || {}
      if additional_data["subtitle_transcription"]
        # Remove the transcription status completely after successful completion
        # The subtitle records themselves will show the current state
        additional_data.delete("subtitle_transcription")
        video_file.update_column(:additional_data, additional_data)
      end
      broadcast_file_update(video_file)
      broadcast_subtitles_update(video_file)
    end

    def determine_target_language(video_file)
      # Get site's enabled languages
      enabled_languages = video_file.site.subtitle_languages || []

      # OpenAI Whisper can auto-detect language, but for now we'll use site preference
      # In the future, we could use the first enabled language or detect from audio
      default_lang = Folio::VideoSubtitle.default_language

      if enabled_languages.include?(default_lang)
        default_lang
      elsif enabled_languages.any?
        enabled_languages.first
      else
        default_lang # Fallback to configurable default
      end
    end

    def generate_expiring_s3_url(video_file, expires_in: 2.hours)
      # Generate an expiring S3 URL (signed URL)
      expiring_url = video_file.file.remote_url(expires: expires_in.from_now)
      Folio::S3.url_rewrite(expiring_url)
    end

    def mark_transcription_failed!(video_file, error_message)
      additional_data = video_file.additional_data || {}
      additional_data["subtitle_transcription"] = {
        "status" => "failed",
        "job_class" => self.class.name,
        "started_at" => additional_data.dig("subtitle_transcription", "started_at") || Time.current.iso8601,
        "failed_at" => Time.current.iso8601,
        "error_message" => error_message,
        "job_id" => job_id
      }
      video_file.update_column(:additional_data, additional_data)
      broadcast_file_update(video_file)
      broadcast_subtitles_update(video_file)
    end
end

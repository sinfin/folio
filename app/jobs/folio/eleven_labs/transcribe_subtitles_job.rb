# frozen_string_literal: true

class Folio::ElevenLabs::TranscribeSubtitlesJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError

  queue_as :default

  # ElevenLabs file size limit for cloud storage URLs
  MAX_FILE_SIZE_BYTES = 2.gigabytes

  def perform(video_file, lang:)
    Rails.logger.info "[TranscribeSubtitlesJob] Starting transcription for video_file ID: #{video_file.id}, language: #{lang}"

    raise "only video files can be transcribed" unless video_file.is_a?(Folio::File::Video)

    begin
      # Validate file size against ElevenLabs limits
      validate_file_size!(video_file)

      # transcribe video directly using ElevenLabs Speech-to-Text API
      # Retry with fresh signed URL if AWS credentials expire
      response = elevenlabs_speech_to_text_request_with_retry(video_file)
      vtt_content = convert_srt_to_vtt(response)

      # Save the subtitles to the video file
      video_file.set_subtitles_text_for(lang, vtt_content)
      video_file.set_subtitles_state_for(lang, "ready")
      save_subtitles!(video_file)

      Rails.logger.info "[TranscribeSubtitlesJob] Transcription completed successfully for video_file ID: #{video_file.id}"

    rescue => e
      Rails.logger.error "[TranscribeSubtitlesJob] Transcription failed for video_file ID: #{video_file.id}: #{e.message}"
      video_file.set_subtitles_state_for(lang, "failed")
      save_subtitles!(video_file)
      raise e
    end
  end

  private
    def validate_file_size!(video_file)
      file_size = video_file.file_size
      if file_size && file_size > MAX_FILE_SIZE_BYTES
        raise "File size #{file_size} bytes exceeds ElevenLabs limit of #{MAX_FILE_SIZE_BYTES} bytes"
      end
    end

    def elevenlabs_speech_to_text_request_with_retry(video_file, max_retries: 3)
      retries = 0
      begin
        # Generate fresh signed URL with reasonable expiration
        signed_url = video_file.file.remote_url(expires: 1.hour.from_now)
        elevenlabs_speech_to_text_request(signed_url)
      rescue => e
        retries += 1
        if retries <= max_retries && (e.message.include?("Failed to read file from cloud storage") || e.message.include?("SignatureDoesNotMatch"))
          Rails.logger.warn "[TranscribeSubtitlesJob] AWS signature/access error (attempt #{retries}/#{max_retries}): #{e.message}. Retrying with fresh signed URL... (Check server time sync if this persists)"
          sleep(2**retries) # Exponential backoff
          retry
        else
          raise e
        end
      end
    end

    def elevenlabs_speech_to_text_request(video_url)
      uri = URI("https://api.elevenlabs.io/v1/speech-to-text")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10 * 60  # Increased timeout for cloud processing
      http.open_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request["xi-api-key"] = ENV.fetch("ELEVENLABS_API_KEY")

      # Build additional_formats JSON for SRT export
      additional_formats = [
        {
          format: "srt",
          max_characters_per_line: 50,
          include_speakers: false,
          include_timestamps: true,
          segment_on_silence_longer_than_s: 0.8,
          max_segment_duration_s: 6.0,
          max_segment_chars: 90
        }
      ]

      # Use correct parameter names from official API documentation
      form_data = [
        ["cloud_storage_url", video_url],
        ["model_id", "scribe_v1"],
        ["diarize", "true"],
        ["timestamps_granularity", "word"],
        ["additional_formats", additional_formats.to_json]
      ]

      request.set_form(form_data, "multipart/form-data")
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        error_message = begin
          error_body = JSON.parse(response.body)
          error_body.dig("detail", "message") || error_body["detail"] || error_body["error"] || response.body
        rescue
          response.body
        end
        Rails.logger.error "[TranscribeSubtitlesJob] ElevenLabs API error: #{response.code} / #{error_message}"
        raise "ElevenLabs API error: #{response.code} / #{error_message}"
      end

      JSON.parse(response.body)
    end

    def convert_srt_to_vtt(response)
      # Get the SRT content from additional_formats in the response
      srt_content = response.dig("additional_formats", 0, "content")

      unless srt_content&.strip&.present?
        Rails.logger.warn "[TranscribeSubtitlesJob] No SRT content found in API response, falling back to word-by-word processing"
        return convert_words_to_vtt(response["words"])
      end

      # Convert SRT format to VTT format
      # SRT uses format: "00:00:01,234 --> 00:00:02,567"
      # VTT uses format: "00:00:01.234 --> 00:00:02.567"
      vtt_content = srt_content.gsub(/(\d{2}:\d{2}:\d{2}),(\d{3})/) { "#{$1}.#{$2}" }

      # Remove SRT sequence numbers (standalone numbers on their own lines)
      # Match: line start, one or more digits, line end, followed by newline and timestamp
      vtt_content = vtt_content.gsub(/^\d+\n(?=\d{2}:\d{2}:\d{2})/, "")

      # Remove WEBVTT header if present (causes validation errors in some systems)
      vtt_content = vtt_content.gsub(/^WEBVTT\s*\n+/, "")

      vtt_content.strip
    end

    def convert_words_to_vtt(words)
      return "" unless words&.any?

      vtt_lines = []

      words.each do |word|
        start_time = format_vtt_time(word["start"])
        end_time = format_vtt_time(word["end"])
        text = word["word"]

        vtt_lines << "#{start_time} --> #{end_time}"
        vtt_lines << text
        vtt_lines << ""
      end

      vtt_lines.join("\n").strip
    end

    def format_vtt_time(seconds)
      return "00:00:00.000" if seconds.nil?

      hours = (seconds / 3600).to_i
      minutes = ((seconds % 3600) / 60).to_i
      secs = seconds % 60

      sprintf("%02d:%02d:%06.3f", hours, minutes, secs)
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
                           type: "Folio::ElevenLabs::TranscribeSubtitlesJob/updated",
                           data: { id: video_file.id },
                         }.to_json,
                         user_ids: message_bus_user_ids
    end
end

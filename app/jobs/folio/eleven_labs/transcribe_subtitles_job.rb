# frozen_string_literal: true

class Folio::ElevenLabs::TranscribeSubtitlesJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError

  queue_as :default

  unique :until_and_while_executing

  # ElevenLabs file size limit for cloud storage URLs
  MAX_FILE_SIZE_BYTES = 1536.megabytes

  def perform(video_file)
    Rails.logger.info "[TranscribeSubtitlesJob] Starting transcription for video_file ID: #{video_file.id}"

    raise "only video files can be transcribed" unless video_file.is_a?(Folio::File::Video)

    begin
      # Mark transcription as started in video metadata
      mark_transcription_started!(video_file)

      # Validate file size against ElevenLabs limits
      file_size_error = validate_file_size(video_file)
      if file_size_error
        Rails.logger.error "[TranscribeSubtitlesJob] File size validation failed for video_file ID: #{video_file.id}: #{file_size_error}"
        mark_transcription_failed!(video_file, file_size_error)
        return
      end

      # Transcribe video using ElevenLabs Speech-to-Text API
      response = elevenlabs_speech_to_text_request(video_file)

      # Extract language detection info from response
      detected_language = response["language_code"]
      language_probability = response["language_probability"].to_f

      # Determine which language to use based on detection and site settings
      target_language = determine_target_language(video_file, detected_language, language_probability)

      # Get or create subtitle for the target language
      subtitle = video_file.subtitle_for(target_language) ||
                 video_file.video_subtitles.build(language: target_language, format: "vtt")

      # Start transcription if subtitle is new
      subtitle.start_transcription!(self.class) if subtitle.new_record?

      # Convert response to VTT format
      vtt_content = convert_srt_to_vtt(response)

      # Mark as ready - this will validate and enable if valid, or save disabled if invalid
      subtitle.mark_transcription_ready!(vtt_content)

      # Store language detection metadata
      subtitle.update_transcription_metadata(
        detected_language: detected_language,
        language_probability: language_probability,
        target_language: target_language,
        detection_date: Time.current.iso8601
      )
      subtitle.save!

      if subtitle.enabled?
        Rails.logger.info "[TranscribeSubtitlesJob] Transcription completed successfully and enabled for video_file ID: #{video_file.id}, language: #{target_language}"
      else
        Rails.logger.warn "[TranscribeSubtitlesJob] Transcription completed but subtitles are invalid and kept disabled for video_file ID: #{video_file.id}, language: #{target_language}"
      end

      # Mark transcription as completed
      mark_transcription_completed!(video_file)

    rescue => e
      error_message = if e.message.include?("ElevenLabs API error: 400 / Audio is too short")
        I18n.t("folio.console.eleven_labs.transcribe_subtitles_job.errors.no_audio_detected")
      elsif e.message.include?('ElevenLabs API error: 400 / {"detail":"Failed to read file from cloud storage"}')
        I18n.t("folio.console.eleven_labs.transcribe_subtitles_job.errors.cloud_storage_read_failed")
      else
        e.message
      end

      Rails.logger.error "[TranscribeSubtitlesJob] Transcription failed for video_file ID: #{video_file.id}: #{error_message}"

      # Mark transcription as failed in video metadata
      mark_transcription_failed!(video_file, error_message)

      # If we have a subtitle instance, mark it as failed
      if defined?(subtitle) && subtitle
        subtitle.mark_transcription_failed!(error_message)
      end

      # Re-raise unless it's a known recoverable error
      should_not_retry = e.message.include?("Audio is too short") ||
                        e.message.include?("Failed to read file from cloud storage")
      raise e unless should_not_retry
    ensure
      broadcast_file_update(video_file)
      broadcast_subtitles_update(video_file)
    end
  end

  private
    def determine_target_language(video_file, detected_language, language_probability)
      # Get site's enabled languages
      enabled_languages = video_file.site.subtitle_languages || []

      # Map ElevenLabs language codes to our standard codes
      normalized_language = normalize_language_code(detected_language)

      # Check if probability > 50% and language is in enabled languages
      if language_probability > 0.5 && enabled_languages.include?(normalized_language)
        normalized_language
      else
        # Fallback to configurable default language
        Folio::VideoSubtitle.default_language
      end
    end

    def normalize_language_code(elevenlabs_code)
      # Use ISO-639 gem to normalize language codes
      # ElevenLabs returns alpha-3 codes, we need alpha-2 codes for our system

      return elevenlabs_code.to_s.downcase if elevenlabs_code.blank?

      # Require the gem when needed
      require "iso-639" unless defined?(ISO_639)

      # Find the language by alpha-3 code
      language = ISO_639.find_by_code(elevenlabs_code.to_s.downcase)

      if language && language.alpha2.present?
        language.alpha2
      else
        # Fallback to original code if not found
        elevenlabs_code.to_s.downcase
      end
    end

    def validate_file_size(video_file)
      file_size = video_file.file_size
      if file_size && file_size > MAX_FILE_SIZE_BYTES
        return I18n.t("folio.console.eleven_labs.transcribe_subtitles_job.errors.file_too_large")
      end
      nil
    end

    def elevenlabs_speech_to_text_request(video_file)
      make_elevenlabs_request(video_file)
    end

    def make_elevenlabs_request(video_file)
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

      # Get the cloud storage URL (using expiring URL for security)
      cloud_storage_url = generate_expiring_s3_url(video_file)

      form_data = [
        ["cloud_storage_url", cloud_storage_url],
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
        raise "[TranscribeSubtitlesJob] No SRT content found in API response"
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

      # Remove any empty lines between a timestamp and the following text line
      # This replaces a timestamp line followed by one or more empty lines, then the text, with just the timestamp and the text
      vtt_content = vtt_content.gsub(/(\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3})\n+(?=\S)/, "\\1\n")

      vtt_content.strip
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
        broadcast_file_update(video_file)
        broadcast_subtitles_update(video_file)
      end
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

    def generate_expiring_s3_url(video_file, expires_in: 2.hours)
      # Generate an expiring S3 URL (signed URL)
      expiring_url = video_file.file.remote_url(expires: expires_in.from_now)
      Folio::S3.url_rewrite(expiring_url)
    end
end

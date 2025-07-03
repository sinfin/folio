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

      # transcribe video directly using ElevenLabs Speech-to-Text API with cloud storage URL
      response = elevenlabs_speech_to_text_request(video_file.file.remote_url)
      Rails.logger.info "[TranscribeSubtitlesJob] API transcription completed. Word count: #{response['words']&.count || 0}"
      
      subtitles = convert_elevenlabs_response_to_vtt(response)

      # save subtitles without VTT header for easier editing
      video_file.set_subtitles_text_for(lang, subtitles.delete_prefix("WEBVTT\n\n"))
      save_subtitles!(video_file)
      
      Rails.logger.info "[TranscribeSubtitlesJob] Transcription completed successfully for video_file ID: #{video_file.id}"
    rescue => e
      Rails.logger.error "[TranscribeSubtitlesJob] Error: #{e.class.name}: #{e.message}"
      
      video_file.set_subtitles_state_for(lang, "failed")
      save_subtitles!(video_file)

      Raven.capture_exception(e) if defined?(Raven)
      Sentry.capture_exception(e) if defined?(Sentry)
    end
  end

  private
    def validate_file_size!(video_file)
      file_size = video_file.file_size
      
      if file_size.nil?
        file_size = get_remote_file_size(video_file.file.remote_url)
      end
      
      if file_size && file_size > MAX_FILE_SIZE_BYTES
        max_size_mb = MAX_FILE_SIZE_BYTES / 1024.0 / 1024.0
        current_size_mb = file_size / 1024.0 / 1024.0
        error_msg = "File size (#{current_size_mb.round(2)} MB) exceeds ElevenLabs limit of #{max_size_mb.round(2)} MB"
        Rails.logger.error "[TranscribeSubtitlesJob] #{error_msg}"
        raise error_msg
      end
    end

    def get_remote_file_size(url)
      uri = URI(url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        response = http.head(uri.path)
        response['content-length']&.to_i
      end
    rescue => e
      Rails.logger.warn "[TranscribeSubtitlesJob] Could not get remote file size: #{e.message}"
      nil
    end

    def elevenlabs_speech_to_text_request(video_url)
      uri = URI("https://api.elevenlabs.io/v1/speech-to-text")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10 * 60  # Increased timeout for cloud processing
      http.open_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request["xi-api-key"] = ENV.fetch("ELEVENLABS_API_KEY")

      form_data = [
        ["cloud_storage_url", video_url],
        ["model_id", "scribe_v1"],
        ["timestamps_granularity", "word"],
        ["tag_audio_events", "true"]
      ]
      request.set_form form_data, "multipart/form-data"

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        error_message = begin
          JSON.parse(response.body).dig("detail", "message") || JSON.parse(response.body)["detail"]
        rescue
          response.body
        end
        Rails.logger.error "[TranscribeSubtitlesJob] ElevenLabs API error: #{response.code} / #{error_message}"
        raise "ElevenLabs API error: #{response.code} / #{error_message}"
      end

      JSON.parse(response.body)
    end

    def convert_elevenlabs_response_to_vtt(response)
      unless response["words"]&.any?
        Rails.logger.warn "[TranscribeSubtitlesJob] No words found in API response"
        return ""
      end

      vtt_content = "WEBVTT\n\n"
      
      response["words"].each do |word|
        # Skip spacing tokens for cleaner subtitles
        next if word["type"] == "spacing"
        
        start_time = format_vtt_time(word["start"])
        end_time = format_vtt_time(word["end"])
        text = word["text"].strip
        
        vtt_content += "#{start_time} --> #{end_time}\n#{text}\n\n"
      end

      vtt_content.strip
    end

    def format_vtt_time(seconds)
      hours = (seconds / 3600).to_i
      minutes = ((seconds % 3600) / 60).to_i
      secs = (seconds % 60)
      
      format("%02d:%02d:%06.3f", hours, minutes, secs)
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
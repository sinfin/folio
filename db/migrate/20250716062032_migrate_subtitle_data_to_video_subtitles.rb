# frozen_string_literal: true

class MigrateSubtitleDataToVideoSubtitles < ActiveRecord::Migration[7.1]
  def up
    say "Migrating subtitle data from JSON storage to VideoSubtitle model..."

    Folio::File::Video.find_each do |video|
      next unless video.additional_data&.dig("subtitles")

      # Skip if video already has VideoSubtitle records (already migrated)
      if video.video_subtitles.any?
        say "Skipping video ID: #{video.id} - already has VideoSubtitle records", true
        next
      end

      say "Processing video ID: #{video.id}", true

      video.additional_data["subtitles"].each do |language, data|
        next unless data.is_a?(Hash)

        # Skip if this looks like already migrated data or unexpected format
        if data.key?("metadata") || (!data.key?("state") && !data.key?("text"))
          say "  - Skipping language #{language}: already migrated or unexpected format", true
          next
        end

        subtitle = Folio::VideoSubtitle.find_or_initialize_by(
          video: video,
          language: language
        )

        # Map old state to new metadata structure
        transcription_data = {}

        if data["state"].present?
          completed_at = nil
          if data["state"] == "ready" || data["state"] == "failed"
            # Use current time if no completion time is available
            completed_at = Time.current.iso8601
          end

          transcription_data = {
            "state" => map_old_state_to_new(data["state"]),
            "processing_started_at" => data["processing_started_at"]&.iso8601,
            "completed_at" => completed_at,
            "last_attempt_at" => data["processing_started_at"]&.iso8601 || Time.current.iso8601,
            "attempts" => 1,
            "job_class" => "Folio::ElevenLabs::TranscribeSubtitlesJob", # Assume ElevenLabs for migrated data
            "error_message" => data["state"] == "failed" ? "Migration: Unknown error" : nil
          }
        end

        # Convert text from SRT to VTT format if present
        converted_text = nil
        if data["text"].present?
          converted_text = convert_srt_to_vtt(data["text"])
        end

        # Determine enabled status - enabled if explicitly true OR if state is ready and enabled is not explicitly false
        enabled_status = if data.key?("enabled")
          data["enabled"] == true
        else
          data["state"] == "ready" # Default: enable if ready
        end

        subtitle.assign_attributes(
          text: converted_text,
          enabled: enabled_status,
          format: "vtt",
          metadata: {
            "transcription" => transcription_data,
            "validation" => {
              "last_validated_at" => Time.current.iso8601,
              "is_valid" => converted_text.present?,
              "validation_errors" => []
            }
          }
        )

        # Save without validations during migration to avoid format validation errors
        if subtitle.save(validate: false)
          say "  - Created subtitle for language: #{language}", true

          # Run validation separately to populate metadata but don't fail on errors
          if subtitle.respond_to?(:validate_and_update_metadata!)
            begin
              subtitle.validate_and_update_metadata!
              subtitle.save(validate: false)
            rescue => e
              say "  - Warning: Could not validate subtitle for #{language}: #{e.message}", true
            end
          end
        else
          say "  - Failed to create subtitle for language: #{language} - #{subtitle.errors.full_messages.join(', ')}", true
        end
      end
    end

    say "Subtitle data migration completed!"
  end

  def down
    say "Migrating VideoSubtitle data back to JSON storage..."

    Folio::VideoSubtitle.find_each do |subtitle|
      video = subtitle.video

      # Initialize subtitles hash if it doesn't exist
      video.additional_data ||= {}
      video.additional_data["subtitles"] ||= {}

      # Map new state back to old format
      old_state = case subtitle.transcription_state
                  when "ready" then "ready"
                  when "processing" then "processing"
                  when "failed" then "failed"
                  else "pending"
      end

      # Convert VTT back to SRT format for rollback compatibility
      srt_text = subtitle.text.present? ? convert_vtt_to_srt(subtitle.text) : subtitle.text

      video.additional_data["subtitles"][subtitle.language] = {
        "enabled" => subtitle.enabled?,
        "state" => old_state,
        "text" => srt_text,
        "processing_started_at" => subtitle.processing_started_at&.iso8601
      }

      video.save!(validate: false)
    end

    # Drop the VideoSubtitle data (the table will be dropped by another migration)
    Folio::VideoSubtitle.delete_all

    say "Subtitle data rollback completed!"
  end

  private
    def map_old_state_to_new(old_state)
      case old_state
      when "ready" then "ready"
      when "processing" then "processing"
      when "failed" then "failed"
      else "pending"
      end
    end

    def convert_srt_to_vtt(srt_content)
      return srt_content if srt_content.blank?

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

    def convert_vtt_to_srt(vtt_content)
      return vtt_content if vtt_content.blank?

      # Convert VTT format back to SRT format for rollback
      # VTT uses format: "00:00:01.234 --> 00:00:02.567"
      # SRT uses format: "00:00:01,234 --> 00:00:02,567"
      srt_content = vtt_content.gsub(/(\d{2}:\d{2}:\d{2})\.(\d{3})/) { "#{$1},#{$2}" }

      # Add SRT sequence numbers
      sequence = 0
      srt_content = srt_content.gsub(/^(\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3})/) do |match|
        sequence += 1
        "#{sequence}\n#{match}"
      end

      srt_content.strip
    end
end

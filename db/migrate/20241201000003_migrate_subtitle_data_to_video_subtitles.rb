# frozen_string_literal: true

class MigrateSubtitleDataToVideoSubtitles < ActiveRecord::Migration[7.1]
  def up
    say "Migrating subtitle data from JSON storage to VideoSubtitle model..."
    
    Folio::File::Video.find_each do |video|
      next unless video.additional_data&.dig('subtitles')

      say "Processing video ID: #{video.id}", true

      video.additional_data['subtitles'].each do |language, data|
        next unless data.is_a?(Hash)

        subtitle = Folio::VideoSubtitle.find_or_initialize_by(
          video: video,
          language: language
        )

        # Map old state to new metadata structure
        transcription_data = {}
        
        if data['state'].present?
          transcription_data = {
            'state' => map_old_state_to_new(data['state']),
            'processing_started_at' => data['processing_started_at']&.iso8601,
            'completed_at' => (data['state'] == 'ready' || data['state'] == 'failed') ? Time.current.iso8601 : nil,
            'attempts' => 1
          }
        end

        subtitle.assign_attributes(
          text: data['text'],
          enabled: data['enabled'] != false && data['state'] == 'ready',
          format: 'vtt',
          metadata: {
            'transcription' => transcription_data,
            'validation' => {
              'last_validated_at' => Time.current.iso8601,
              'is_valid' => true,
              'validation_errors' => []
            }
          }
        )

        if subtitle.save
          say "  - Created subtitle for language: #{language}", true
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
      video.additional_data['subtitles'] ||= {}
      
      # Map new state back to old format
      old_state = case subtitle.transcription_state
                  when 'ready' then 'ready'
                  when 'processing' then 'processing'
                  when 'failed' then 'failed'
                  else 'pending'
                  end

      video.additional_data['subtitles'][subtitle.language] = {
        'enabled' => subtitle.enabled?,
        'state' => old_state,
        'text' => subtitle.text,
        'processing_started_at' => subtitle.processing_started_at
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
    when 'ready' then 'ready'
    when 'processing' then 'processing'
    when 'failed' then 'failed'
    else 'pending'
    end
  end
end 
# frozen_string_literal: true

class Folio::SubtitleValidationService
  def self.validate_and_update_metadata(subtitle, enable_if_valid: false)
    new(subtitle, enable_if_valid: enable_if_valid).validate_and_update_metadata
  end

  def initialize(subtitle, enable_if_valid: false)
    @subtitle = subtitle
    @enable_if_valid = enable_if_valid
  end

  def validate_and_update_metadata
    # Set validation flag
    @subtitle.validate_content = true

    # Trigger validation
    is_valid = @subtitle.valid?

    # Update validation metadata
    if @subtitle.errors.any?
      @subtitle.update_validation_metadata(false, @subtitle.errors.full_messages)

      # Prevent enabling if there are validation errors
      if @enable_if_valid
        @subtitle.enabled = false
      end
    else
      @subtitle.update_validation_metadata(true, [])

      # Enable if validation passes and requested
      if @enable_if_valid
        @subtitle.enabled = true
      end
    end

    # Clear validation flag
    @subtitle.validate_content = false

    # Return whether validation passed
    is_valid
  end

  def self.validate_vtt_format(text)
    return [] if text.blank?

    errors = []
    lines = text.strip.lines
    last_line_was_timecode = false

    lines.each_with_index do |line, index|
      stripped = line.strip

      if stripped.empty? || stripped.start_with?("NOTE")
        last_line_was_timecode = false
        next
      end

      if /^\d+$/.match?(stripped)
        last_line_was_timecode = false
        next
      end

      if /\A\d{2}:\d{2}:\d{2}\.\d{3}\s-->\s\d{2}:\d{2}:\d{2}\.\d{3}/.match?(stripped)
        last_line_was_timecode = true
        next
      end

      unless last_line_was_timecode
        errors << { type: :invalid_subtitle_block, line: index + 1 }
        break
      end
    end

    errors
  end
end

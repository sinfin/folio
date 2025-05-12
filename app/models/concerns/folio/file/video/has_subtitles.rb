# frozen_string_literal: true

module Folio::File::Video::HasSubtitles
  extend ActiveSupport::Concern

  class_methods do
    def enabled_subtitle_languages
      Rails.application.config.folio_files_video_enabled_subtitle_languages
    end
  end

  included do
    # subtitles hash structure
    # - state - processing, ready, failed
    # - text - subtitles itself
    store_accessor :additional_data, :subtitles
    store :subtitles, accessors: self.enabled_subtitle_languages, prefix: :subtitles
    enabled_subtitle_languages.each do |lang|
      store :"subtitles_#{lang}", accessors: %w[state text], prefix: :"subtitles_#{lang}"
    end

    # if subtitle text is set, always set the state to ready
    enabled_subtitle_languages.each do |lang|
      define_method :"subtitles_#{lang}_text=" do |value|
        send("subtitles_#{lang}_state=", "ready")
        super(value)
      end
    end

    validate :validate_subtitles_format
  end

  def set_subtitles_state_for(lang, state)
    send("subtitles_#{lang}_state=", state.to_s)
  end

  def set_subtitles_text_for(lang, text)
    send("subtitles_#{lang}_text=", text.to_s)
  end

  def get_subtitles_state_for(lang)
    send("subtitles_#{lang}_state")
  end

  def get_subtitles_text_for(lang)
    send("subtitles_#{lang}_text")
  end

  def after_process
    super
    transcribe_subtitles!
  end

  def transcribe_subtitles!
    return unless transcribe_subtitles_job_class.present?

    self.class.enabled_subtitle_languages.each do |lang|
      send("subtitles_#{lang}=", { "state" => "processing" })
    end
    update_columns(additional_data:,
                   updated_at: current_time_from_proper_timezone)

    self.class.enabled_subtitle_languages.each do |lang|
      transcribe_subtitles_job_class.perform_later(self, lang: lang)
    end
  end

  def transcribe_subtitles_job_class
    # enable in main app
    # Folio::OpenAi::TranscribeSubtitlesJob
  end

  private
    def validate_subtitles_format
      self.class.enabled_subtitle_languages.each do |lang|
        validate_subtitles_format_for(lang)
      end
    end

    def validate_subtitles_format_for(lang)
      attribute_name = "subtitles_#{lang}_text"
      value = get_subtitles_text_for(lang)

      return if value.blank?

      errors.add(attribute_name, :invalid) unless value.is_a?(String)

      lines = value.strip.lines
      last_line_was_timecode = false

      lines.each_with_index do |line, index|
        stripped = line.strip

        if stripped.empty? || stripped.start_with?("NOTE")
          # empty line or note/comment
          last_line_was_timecode = false
          next
        end

        if /^\d+$/.match?(stripped)
          # sequence number (optional)
          last_line_was_timecode = false
          next
        end

        if /\A\d{2}:\d{2}:\d{2}\.\d{3}\s-->\s\d{2}:\d{2}:\d{2}\.\d{3}/.match?(stripped)
          # timecode line
          last_line_was_timecode = true
          next
        end

        # text line — must follow a timecode line
        unless last_line_was_timecode
          errors.add(attribute_name, :invalid_subtitle_block, line: index + 1)
          return
        end
      end
    end
end

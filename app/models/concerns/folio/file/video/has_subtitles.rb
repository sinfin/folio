# frozen_string_literal: true

module Folio::File::Video::HasSubtitles
  extend ActiveSupport::Concern

  included do
    has_many :video_subtitles, class_name: "Folio::VideoSubtitle",
             foreign_key: :video_id, dependent: :destroy

    # Alias for backward compatibility
    alias_method :subtitles, :video_subtitles
  end

  class_methods do
    def enabled_subtitle_languages
      if Folio::Current.site&.subtitle_languages&.any?
        Folio::Current.site.subtitle_languages
      else
        Rails.application.config.folio_files_video_enabled_subtitle_languages
      end
    end

    def transcribe_subtitles_job_class
      # enable in main app, choose one:
      # Folio::OpenAi::TranscribeSubtitlesJob        # for OpenAI Whisper
      # Folio::ElevenLabs::TranscribeSubtitlesJob    # for ElevenLabs
    end
  end

  def subtitle_for(language)
    video_subtitles.for_language(language).first
  end

  def subtitle_for!(language)
    subtitle_for(language) || video_subtitles.create!(language: language)
  end

  def subtitles_enabled?
    site&.subtitle_auto_generation_enabled || false
  end

  # Backward compatibility methods
  def set_subtitles_text_for(lang, text)
    subtitle = subtitle_for!(lang)

    # Check if this was auto-generated and mark manual override
    if subtitle.auto_generated?
      subtitle.update_transcription_metadata("state" => "manual_override")
    end

    subtitle.text = text
    subtitle.mark_manual_edit!
    subtitle.save!
  end

  def set_subtitles_state_for(lang, state)
    subtitle = subtitle_for!(lang)
    case state.to_s
    when "processing"
      # This should only be called by transcription jobs
      job_class = self.class.transcribe_subtitles_job_class
      subtitle.start_transcription!(job_class) if job_class
    when "ready"
      # This should be called with text content
      # For now, just mark as ready if called directly
      subtitle.mark_transcription_ready!(subtitle.text || "")
    when "failed"
      subtitle.mark_transcription_failed!("Transcription failed")
    end
  end

  def get_subtitles_text_for(lang)
    subtitle_for(lang)&.text
  end

  def get_subtitles_state_for(lang)
    subtitle = subtitle_for(lang)
    return "pending" unless subtitle

    if subtitle.auto_generated?
      subtitle.transcription_state
    else
      subtitle.enabled? ? "ready" : "pending"
    end
  end

  def get_subtitles_processing_started_at_for(lang)
    subtitle = subtitle_for(lang)
    return nil unless subtitle&.auto_generated?

    subtitle.processing_started_at
  end

  def after_process
    super
    transcribe_subtitles!
  end

  def transcribe_subtitles!(force: false)
    return unless subtitles_enabled?

    # Check if already processing (unless forced)
    if !force && (subtitles_transcription_processing? || video_subtitles.any?(&:processing?))
      return
    end

    # Start transcription job - ElevenLabs will determine the language
    self.class.transcribe_subtitles_job_class.perform_later(self)
  end

  # Check if subtitle transcription job is currently running
  def subtitles_transcription_processing?
    additional_data&.dig("subtitle_transcription", "status") == "processing"
  end

  # Get subtitle transcription status for UI display
  def subtitles_transcription_status
    additional_data&.dig("subtitle_transcription", "status")
  end

  # Get subtitle transcription error message if failed
  def subtitles_transcription_error
    additional_data&.dig("subtitle_transcription", "error_message")
  end

  # Get when subtitle transcription started
  def subtitles_transcription_started_at
    started_at = additional_data&.dig("subtitle_transcription", "started_at")
    Time.parse(started_at) if started_at
  rescue ArgumentError
    nil
  end

  # Dynamic method generation for backward compatibility
  def self.included(base)
    super

    base.class_eval do
      after_initialize :define_language_methods
    end
  end

  module ClassMethods
    def define_subtitle_language_methods
      # Only define methods if we have a database connection and the enabled languages are available
      return unless defined?(Rails) && Rails.application&.initialized? &&
                    respond_to?(:enabled_subtitle_languages)

      begin
        enabled_subtitle_languages.each do |lang|
          define_method("subtitles_#{lang}") do
            subtitle_for(lang)
          end

          define_method("subtitles_#{lang}_text") do
            get_subtitles_text_for(lang)
          end

          define_method("subtitles_#{lang}_text=") do |value|
            set_subtitles_text_for(lang, value)
          end

          define_method("subtitles_#{lang}_enabled?") do
            subtitle_for(lang)&.enabled? || false
          end

          define_method("subtitles_#{lang}_state") do
            get_subtitles_state_for(lang)
          end

          define_method("subtitles_#{lang}_processing_started_at") do
            get_subtitles_processing_started_at_for(lang)
          end
        end
      rescue => e
        # Silently fail during class loading if database isn't ready
        Rails.logger&.debug "Could not define subtitle language methods: #{e.message}"
      end
    end
  end

  private
    def enabled_languages
      site&.subtitle_languages&.any? ? site.subtitle_languages :
        self.class.enabled_subtitle_languages
    end

    def define_language_methods
      return unless self.class.respond_to?(:enabled_subtitle_languages)

      begin
        self.class.enabled_subtitle_languages.each do |lang|
          define_singleton_method("subtitles_#{lang}") do
            subtitle_for(lang)
          end

          define_singleton_method("subtitles_#{lang}_text") do
            get_subtitles_text_for(lang)
          end

          define_singleton_method("subtitles_#{lang}_text=") do |value|
            set_subtitles_text_for(lang, value)
          end

          define_singleton_method("subtitles_#{lang}_enabled?") do
            subtitle_for(lang)&.enabled? || false
          end

          define_singleton_method("subtitles_#{lang}_state") do
            get_subtitles_state_for(lang)
          end

          define_singleton_method("subtitles_#{lang}_processing_started_at") do
            get_subtitles_processing_started_at_for(lang)
          end
        end
      rescue => e
        # Silently fail during initialization if database isn't ready
        Rails.logger&.debug "Could not define singleton subtitle methods: #{e.message}"
      end
    end
end

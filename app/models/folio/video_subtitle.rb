# frozen_string_literal: true

class Folio::VideoSubtitle < Folio::ApplicationRecord
  belongs_to :video, class_name: "Folio::File::Video"

  validates :language, presence: true,
            uniqueness: { scope: :video_id }
  validates :format, inclusion: { in: %w[vtt] }

  # Conditional validation - only when explicitly requested
  validates :text, presence: true, if: :should_validate_content?
  validate :validate_subtitle_format, if: :should_validate_content?

  store_accessor :metadata, :transcription, :manual_edits, :validation

  scope :enabled, -> { where(enabled: true) }
  scope :for_language, ->(lang) { where(language: lang) }
  scope :auto_generated, -> { where("metadata -> 'transcription' ->> 'job_class' IS NOT NULL") }
  scope :manually_created, -> { where("metadata -> 'transcription' ->> 'job_class' IS NULL") }

  # Scope that adds calculated last_activity_at for efficient querying
  scope :with_last_activity, -> {
    select("#{table_name}.*,
            GREATEST(
              COALESCE((metadata->'transcription'->>'completed_at')::timestamp, updated_at),
              COALESCE((metadata->'manual_edits'->>'last_edited_at')::timestamp, updated_at),
              updated_at
            ) as calculated_last_activity_at")
  }

  attr_accessor :validate_content, :user_action

  def site
    video.site
  end

  def self.default_language
    # Configurable default language for subtitle creation
    Rails.application.config.try(:folio_files_video_default_subtitle_language) || "cs"
  end

  def display_name
    language_name = I18n.t("folio.locale.languages.#{language}", default: language.upcase)
    "#{I18n.t('folio.file.subtitle.title')} (#{language_name})"
  end

  # Automatic transcription state management
  def transcription_state
    transcription&.dig("state") || "pending"
  end

  def start_transcription!(job_class)
    update_transcription_metadata(
      job_class: job_class.to_s,
      state: "processing",
      processing_started_at: Time.current.iso8601,
      attempts: (transcription&.dig("attempts") || 0) + 1,
      last_attempt_at: Time.current.iso8601,
      error_message: nil  # Clear any previous error message when starting new attempt
    )

    # Clear manual edits since retranscription will overwrite any manual changes
    clear_manual_edit_metadata!

    save!
  end

  def mark_transcription_ready!(text_content)
    self.text = text_content

    # Always validate and update metadata
    self.validate_content = true
    valid? # Trigger validation

    update_transcription_metadata(
      state: "ready",
      completed_at: Time.current.iso8601,
      error_message: nil  # Clear any previous error message on success
    )

    if errors.any?
      # Store validation errors and keep disabled
      self.enabled = false
      update_validation_metadata(false, errors.full_messages)
    else
      # Enable if validation passes
      self.enabled = true
      update_validation_metadata(true, [])
    end

    self.validate_content = false
    save!(validate: false) # Skip Rails validation since we handled it manually
  end

  def mark_transcription_failed!(error_message)
    update_transcription_metadata(
      state: "failed",
      completed_at: Time.current.iso8601,
      error_message: error_message
    )
    save!
  end

  def mark_manual_edit!
    # Just track that it was manually edited, no complex state changes
    update_manual_edits_metadata
    save!
  end

  # Check if this subtitle was auto-generated
  def auto_generated?
    transcription&.dig("job_class").present?
  end

  def last_error_message
    transcription&.dig("error_message")
  end

  def processing?
    transcription_state == "processing"
  end

  def processing_started_at
    started_at = transcription&.dig("processing_started_at")
    Time.parse(started_at) if started_at
  rescue ArgumentError
    nil
  end

  def completed_at
    completed_at = transcription&.dig("completed_at")
    Time.parse(completed_at) if completed_at
  rescue ArgumentError
    nil
  end

  def last_attempt_at
    attempt_at = transcription&.dig("last_attempt_at")
    Time.parse(attempt_at) if attempt_at
  rescue ArgumentError
    nil
  end

  # Validation metadata
  def validation_errors
    validation&.dig("validation_errors") || []
  end

  def last_edited_at
    edited_at = manual_edits&.dig("last_edited_at")
    Time.parse(edited_at) if edited_at
  rescue ArgumentError
    nil
  end

  # Simplified status for UI display
  def status_for_display
    if processing?
      "processing"
    elsif text.present? && enabled?
      "enabled"
    elsif text.present? && !enabled?
      "disabled"
    else
      "empty"
    end
  end

  def last_activity_at
    # Use calculated value if available (from with_last_activity scope)
    if respond_to?(:calculated_last_activity_at) && calculated_last_activity_at.present?
      calculated_last_activity_at
    else
      # Fallback to runtime calculation for individual instances
      [completed_at, last_edited_at, updated_at].compact.max
    end
  end

  def update_transcription_metadata(updates)
    self.transcription = (transcription || {}).merge(updates.stringify_keys)
  end

  def update_manual_edits_metadata
    self.manual_edits = {
      "last_edited_at" => Time.current.iso8601
    }
  end

  def clear_manual_edit_metadata!
    self.manual_edits = {}
  end

  def validate_and_update_metadata!
    # Use shared validation service for consistent validation handling
    !Folio::SubtitleValidationService.validate_and_update_metadata(self)
  end

  def update_validation_metadata(is_valid, errors)
    self.validation = {
      "last_validated_at" => Time.current.iso8601,
      "is_valid" => is_valid,
      "validation_errors" => errors
    }
  end

  private
    def should_validate_content?
      validate_content || user_action == :enable
    end

    def validate_subtitle_format
      return if text.blank?

      case format
      when "vtt"
        validate_vtt_format
      end
    end

    def validate_vtt_format
      validation_errors = Folio::SubtitleValidationService.validate_vtt_format(text)
      validation_errors.each do |error|
        errors.add(:text, error[:type], line: error[:line])
      end
    end
end

# == Schema Information
#
# Table name: folio_video_subtitles
#
#  id         :bigint(8)        not null, primary key
#  video_id   :bigint(8)        not null
#  language   :string           not null
#  format     :string           default("vtt")
#  text       :text
#  enabled    :boolean          default(FALSE)
#  metadata   :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_video_subtitles_on_enabled                (enabled)
#  index_folio_video_subtitles_on_language               (language)
#  index_folio_video_subtitles_on_metadata               (metadata) USING gin
#  index_folio_video_subtitles_on_video_id               (video_id)
#  index_folio_video_subtitles_on_video_id_and_language  (video_id,language) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (video_id => folio_files.id)
#
#

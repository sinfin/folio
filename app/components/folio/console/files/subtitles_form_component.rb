# frozen_string_literal: true

class Folio::Console::Files::SubtitlesFormComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def render?
    @file.try(:subtitles_enabled?) || @file.video_subtitles.any? || @file.site.subtitle_languages.any?
  end

  def data
    stimulus_controller("f-c-files-subtitles-form",
                        values: {
                          file_id: @file.id,
                          reload_url: reload_url,
                          retranscribe_url: helpers.url_for([:retranscribe_subtitles, :console, :api, @file, format: :json])
                        },
                        action: {
                          "f-c-files-subtitle-form:subtitleDeleted" => "subtitleDeleted",
                          "f-c-files-subtitle-form:newSubtitleRemoved" => "newSubtitleRemoved",
                          "f-c-files-subtitle-form:reload" => "reload"
                        })
  end

  def reload_url
    helpers.url_for([:subtitles_html, :console, :api, @file, format: :json])
  end

  def enabled_languages
    @file.site.subtitle_languages
  end

  def existing_subtitles
    @existing_subtitles ||= begin
      subtitles = @file.video_subtitles.includes(:video)

      # Order by site's language preference order
      subtitles.sort_by { |subtitle| enabled_languages.index(subtitle.language) || 999 }
    end
  end

  def available_languages_for_addition
    @available_languages_for_addition ||= enabled_languages - existing_subtitles.map(&:language)
  end

  def transcription_enabled?
    @file.site.subtitle_auto_generation_enabled? &&
      @file.class.transcribe_subtitles_job_class.present?
  end

  def video_transcription_status
    @file.subtitles_transcription_status
  end

  def video_transcription_error
    @file.subtitles_transcription_error
  end

  def show_transcription_progress?
    video_transcription_status == "processing"
  end

  def subtitle_form_component_for(subtitle, expanded: false)
    Folio::Console::Files::SubtitleFormComponent.new(
      file: @file,
      subtitle: subtitle,
      expanded: expanded
    )
  end

  def last_activity_text_for(subtitle)
    return t(".never_processed") unless subtitle.last_activity_at

    activities = []

    if subtitle.auto_generated?
      # Show transcription info
      completed_at = subtitle.metadata&.dig("transcription", "completed_at")
      if completed_at
        transcription_time = time_ago_in_words(Time.parse(completed_at))
        activities << t(".last_activity.transcribed", time: transcription_time)
      end
    end

    # Show manual edit info if any
    last_edited_at = subtitle.metadata&.dig("manual_edits", "last_edited_at")
    if last_edited_at
      edit_time = time_ago_in_words(Time.parse(last_edited_at))
      activities << t(".last_activity.edited", time: edit_time)
    end

    # If neither transcription nor manual edits, show generic activity
    if activities.empty?
      time_ago = time_ago_in_words(subtitle.last_activity_at)
      activities << t(".last_activity.generic", time: time_ago)
    end

    activities.join(" • ")
  end
end

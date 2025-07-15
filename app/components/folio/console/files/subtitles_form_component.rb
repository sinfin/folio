# frozen_string_literal: true

class Folio::Console::Files::SubtitlesFormComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def render?
    @file.class.try(:subtitles_enabled?)
  end

  def data
    stimulus_controller("f-c-files-subtitles-form",
                        values: {
                          file_id: @file.id,
                          reload_url: reload_url,
                          retranscribe_all_url: helpers.url_for([:retranscribe_subtitles, :console, :api, @file, format: :json])
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
      subtitles = @file.video_subtitles.includes(:video).order(:language)
      
      # Ensure validation errors are populated for disabled subtitles
      subtitles.each do |subtitle|
        ensure_validation_errors_populated(subtitle)
      end
      
      subtitles
    end
  end

  def available_languages_for_addition
    @available_languages_for_addition ||= enabled_languages - existing_subtitles.map(&:language)
  end

  def transcription_enabled?
    @file.site.subtitle_auto_generation_enabled? && 
      @file.class.transcribe_subtitles_job_class.present?
  end

  def any_subtitles_processing?
    @file.subtitles_transcription_processing? || existing_subtitles.any?(&:processing?)
  end

  def video_transcription_status
    @file.subtitles_transcription_status
  end

  def video_transcription_error
    @file.subtitles_transcription_error
  end

  def show_transcription_progress?
    video_transcription_status == 'processing'
  end

  def form_for_subtitle(subtitle, &block)
    opts = {
      url: helpers.polymorphic_path([:console, :api, @file]) + "/subtitles/#{subtitle.language}",
      method: subtitle.persisted? ? :patch : :post,
      as: :subtitle,
      html: { 
        class: "f-c-files-subtitles-form__subtitle-form",
        data: stimulus_action("submit->f-c-files-subtitles-form#onSubtitleFormSubmit").merge({
          "f-c-files-subtitles-form-language-param" => subtitle.language,
          "remote" => "false"
        })
      }
    }

    simple_form_for(subtitle, opts, &block)
  end

  def status_badge_for(subtitle)
    case subtitle.status_for_display
    when 'processing'
      content_tag(:span, class: "badge badge-warning") do
        concat folio_icon(:reload, height: 16, class: "spin me-1")
        concat t('.status.processing')
      end
    when 'ready'
      content_tag(:span, class: "badge badge-success") do
        concat folio_icon(:check, height: 16, class: "me-1")
        concat t('.status.ready')
      end
    when 'disabled'
      content_tag(:span, class: "badge badge-secondary") do
        concat folio_icon(:pause, height: 16, class: "me-1")
        concat t('.status.disabled')
      end
    else
      content_tag(:span, class: "badge badge-light") do
        concat folio_icon(:plus, height: 16, class: "me-1")
        concat t('.status.empty')
      end
    end
  end

  def last_activity_text_for(subtitle)
    return t('.never_processed') unless subtitle.last_activity_at

    time_ago = time_ago_in_words(subtitle.last_activity_at)
    
    if subtitle.auto_generated?
      if subtitle.edit_count > 0
        t('.last_activity.auto_with_edits', time: time_ago, edits: subtitle.edit_count)
      else
        t('.last_activity.auto_only', time: time_ago)
      end
    else
      t('.last_activity.manual_only', time: time_ago)
    end
  end

  private

  def ensure_validation_errors_populated(subtitle)
    # Skip if already has validation errors or if enabled
    return if subtitle.enabled? || subtitle.validation_errors.any?
    
    # Skip if no text content
    return if subtitle.text.blank?
    
    # Validate the content to populate errors
    subtitle.validate_content = true
    unless subtitle.valid?
      subtitle.update_validation_metadata(false, subtitle.errors.full_messages)
      subtitle.save(validate: false)
    end
    subtitle.validate_content = false
  end
end 
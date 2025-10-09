# frozen_string_literal: true

class Folio::Console::Files::SubtitleFormComponent < Folio::Console::ApplicationComponent
  def initialize(file:, subtitle: nil, language: nil, expanded: false)
    @file = file
    @subtitle = subtitle
    @language = language
    @expanded = expanded

    # If no subtitle provided but language is, create a new unsaved subtitle
    if @subtitle.nil? && @language.present?
      @subtitle = @file.video_subtitles.build(
        language: @language,
        text: "",
        enabled: false,
        format: "vtt"
      )
    end
  end

  def render?
    @subtitle.present?
  end

  def data
    stimulus_controller("f-c-files-subtitle-form",
                        values: {
                          language: @subtitle.language,
                          file_id: @file.id,
                          persisted: @subtitle.persisted?,
                          subtitles_reload_url: helpers.url_for([:subtitles_html, :console, :api, @file, format: :json])
                        })
  end

  def form_for_subtitle(&block)
    # Determine the correct URL and method based on whether subtitle is persisted
    if @subtitle.persisted?
      url = helpers.polymorphic_path([:console, :api, @file]) + "/subtitles/#{@subtitle.language}"
      method = :patch
    else
      url = helpers.polymorphic_path([:console, :api, @file]) + "/subtitles/#{@subtitle.language}"
      method = :post
    end

    opts = {
      url: url,
      method: method,
      as: :subtitle,
      html: {
        class: "f-c-files-subtitle-form__form",
        id: "subtitle-form-#{@subtitle.language}",
        data: stimulus_action("submit->f-c-files-subtitle-form#onFormSubmit").merge({
          "remote" => "false"
        })
      }
    }

    helpers.simple_form_for(@subtitle, opts, &block)
  end

  def status_badge_for(subtitle)
    case subtitle.status_for_display
    when "processing"
      content_tag(:span, class: "badge badge-warning") do
        concat folio_icon(:reload, height: 16, class: "spin me-1")
        concat t(".status.processing")
      end
    when "enabled"
      content_tag(:span, class: "badge badge-success") do
        concat folio_icon(:check, height: 16, class: "me-1")
        concat t(".status.enabled")
      end
    when "disabled"
      if subtitle.validation_errors.any?
        content_tag(:span, class: "badge badge-danger") do
          concat folio_icon(:alert, height: 16, class: "me-1")
          concat t(".status.disabled_with_errors", count: subtitle.validation_errors.length)
        end
      else
        content_tag(:span, class: "badge badge-secondary") do
          concat folio_icon(:pause, height: 16, class: "me-1")
          concat t(".status.disabled")
        end
      end
    else
      content_tag(:span, class: "badge badge-secondary") do
        concat folio_icon(:plus, height: 16, class: "me-1")
        concat t(".status.empty")
      end
    end
  end

  def last_activity_text_for(subtitle)
    if subtitle.last_edited_at.present?
      t(".last_manual_edit", time: time_ago_in_words(subtitle.last_edited_at))
    elsif subtitle.completed_at.present?
      t(".last_transcription", time: time_ago_in_words(subtitle.completed_at))
    elsif subtitle.processing_started_at.present?
      t(".last_transcription", time: time_ago_in_words(subtitle.processing_started_at))
    else
      t(".no_activity")
    end
  end

  def unique_id_suffix
    @subtitle.language
  end

  def accordion_id
    "subtitle-#{unique_id_suffix}"
  end

  def accordion_header_id
    "#{accordion_id}-header"
  end

  def accordion_body_id
    "#{accordion_id}-body"
  end

  def display_name
    @subtitle.display_name
  end
end

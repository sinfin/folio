# frozen_string_literal: true

class Folio::Console::Files::HasSubtitlesFormComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def render?
    @file.class.try(:subtitles_enabled?)
  end

  def data
    stimulus_controller("f-c-files-has-subtitles-form",
                        values: {
                          file_id: @file.id,
                          reload_url: url_for([:subtitles_html, :console, :api, @file]),
                          retranscribe_url: url_for([:retranscribe_subtitles, :console, :api, @file]),
                        },
                        action: {
                          "f-c-files-has-subtitles-form:reload" => "reload",
                        })
  end

  def form(&block)
    opts = {
      url: url_for([:update_subtitles, :console, :api, @file]),
      as: :file,
      html: { class: "f-c-files-has-subtitles-form__form", data: stimulus_action(submit: "onFormSubmit") },
    }

    simple_form_for(@file, opts, &block)
  end

  def form_buttons
    [
      {
        variant: :primary,
        type: :submit,
        label: t(".submit"),
      },
      {
        variant: :gray,
        label: t("folio.console.actions.cancel"),
        data: stimulus_action(click: "cancelForm"),
      },
    ]
  end
end

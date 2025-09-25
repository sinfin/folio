# frozen_string_literal: true

class Folio::Console::Files::Batch::FormComponent < Folio::Console::ApplicationComponent
  def initialize(file_klass:, files: [])
    @file_klass = file_klass
    @files = files
  end

  def data
    stimulus_controller("f-c-files-batch-form",
                        values: {
                          url: url_for([:batch_update, :console, :api, @file_klass]),
                        },
                        action: {
                          keypress: "onKeypress",
                        })
  end

  def form(&block)
    helpers.simple_fields_for(:file_attributes, @file_klass.new, &block)
  end

  def form_buttons_model
    [
      {
        variant: :gray,
        label: t("folio.console.actions.cancel"),
        data: stimulus_action(click: "cancel")
      },
      {
        variant: :primary,
        label: t("folio.console.actions.save"),
        type: :button,
        data: stimulus_action(click: "submit")
      },
    ]
  end

  def input(f, attribute, opts = {})
    opts ||= {}
    opts[:hint] = false
    opts[:autocomplete] = true

    opts[:wrapper_html] = { class: "f-c-files-batch-form__form-group" }

    values = @files.map { |file| file.public_send(attribute).presence }.uniq

    if values.present?
      if values.size == 1
        opts[:input_html] ||= {}
        opts[:input_html][:value] = values.first
      else
        opts[:wrapper_html][:class] += " f-c-files-batch-form__form-group--has-values form-group-invalid"
        opts[:input_html] ||= {}
        opts[:input_html][:class] = "is-invalid"
        opts[:hint] = t(".has_values_hint")
        opts[:placeholder] = t(".has_values_placeholder")
      end
    end

    f.input(attribute, opts)
  end
end

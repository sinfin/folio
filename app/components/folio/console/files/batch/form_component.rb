# frozen_string_literal: true

class Folio::Console::Files::Batch::FormComponent < Folio::Console::ApplicationComponent
  def initialize(file_klass:, files: [], attribute_overrides: nil)
    @file_klass = file_klass
    @files = files
    @attribute_overrides = attribute_overrides&.symbolize_keys || {}
    Rails.logger.info("Batch::FormComponent.init -> attribute_overrides: #{attribute_overrides}")
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
    opts[:input_html] ||= {}

    values = if @attribute_overrides[attribute].present?
      Rails.logger.info("Batch::FormComponent.input(#{attribute}) value from override")
      [@attribute_overrides[attribute]]
    else
      @files.filter_map { |file| file.public_send(attribute).presence }.uniq
    end
    Rails.logger.info("Batch::FormComponent.input(#{attribute}) values -> #{values}")

    if values.blank?
      opts.delete(:input_html)
    else
      if values.size == 1
        opts[:input_html][:value] = values.first
      else
        Rails.logger.error("More values for #{attribute}: #{values}")
        opts[:wrapper_html][:class] += " f-c-files-batch-form__form-group--has-values form-group-invalid"
        opts[:input_html][:class] = "is-invalid"
        opts[:hint] = t(".has_values_hint")
        opts[:placeholder] = t(".has_values_placeholder")
      end
    end

    f.input(attribute, opts)
  end

  def files_in_processing_count
    @files_in_processing_count ||= (@files.select { |f| f.processing? || f.unprocessed? }).size
  end

  def title
    (1 < @files.size) ? t(".title.multiple") : t(".title.single")
  end
end

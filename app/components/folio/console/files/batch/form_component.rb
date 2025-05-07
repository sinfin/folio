# frozen_string_literal: true

class Folio::Console::Files::Batch::FormComponent < Folio::Console::ApplicationComponent
  def initialize(file_klass:)
    @file_klass = file_klass
  end

  def data
    stimulus_controller("f-c-files-batch-form")
  end

  def form(&block)
    opts = {
      url: url_for([:batch_update, :console, :api, @file_klass]),
      as: :file_attributes,
      html: { class: "f-c-files-batch-form__form" },
    }

    simple_form_for(@file_klass.new, opts, &block)
  end

  def form_buttons_model
    [
      { variant: :gray, label: t("folio.console.actions.cancel"), data: stimulus_action(click: "cancel") },
      { variant: :primary, label: t("folio.console.actions.save"), type: :submit },
    ]
  end
end

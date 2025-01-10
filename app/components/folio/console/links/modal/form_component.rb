# frozen_string_literal: true

class Folio::Console::Links::Modal::FormComponent < Folio::Console::ApplicationComponent
  def initialize(url_json:)
    @url_json = url_json
  end

  def data
    stimulus_controller("f-c-links-modal-form",
                        action: { "f-c-links-modal-url-picker:changed" => "changedInUrlPicker" })
  end

  def buttons_model
    [
      {
        variant: :gray,
        label: t(".cancel"),
        data: stimulus_action("onCancelClick")
      },
      {
        variant: :primary,
        type: :submit,
        label: t(".submit"),
      },
    ]
  end
end

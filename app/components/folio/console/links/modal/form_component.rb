# frozen_string_literal: true

class Folio::Console::Links::Modal::FormComponent < Folio::Console::ApplicationComponent
  VALID_REL_VALUES = %w[alternate author bookmark external help license next nofollow noopener noreferrer prev search tag]

  def initialize(url_json:, json: true, preferred_label: nil, absolute_urls: false)
    @url_json = url_json
    @json = json
    @preferred_label = preferred_label
    @absolute_urls = absolute_urls
  end

  def data
    stimulus_controller("f-c-links-modal-form",
                        action: { "f-c-links-modal-url-picker:changed" => "changedInUrlPicker" },
                        values: {
                          json: @json,
                          preferred_label: @preferred_label,
                          absolute_urls: @absolute_urls,
                        })
  end

  def buttons_model
    [
      {
        variant: :gray,
        label: t(".cancel"),
        data: stimulus_modal_close,
      },
      {
        variant: :primary,
        type: :submit,
        label: t(".submit"),
      },
    ]
  end
end

# frozen_string_literal: true

class Folio::Console::Ui::InPlaceInputComponent < Folio::Console::ApplicationComponent
  def initialize(name:, record:, cleave: false)
    @name = name
    @record = record
    @value = record.send(name)
    @cleave = cleave
    @textarea = !cleave && @record.class.columns_hash[name.to_s].type == :text
  end

  def url
    url_for([:console, @record])
  end

  def data
    stimulus_controller("f-c-ui-in-place-input",
                        action: {
                          "f-c-ui-ajax-input:success" => "onSuccess",
                          "f-c-ui-ajax-input:blur" => "onBlur",
                        },
                        values: {
                          editing: false,
                        })
  end
end

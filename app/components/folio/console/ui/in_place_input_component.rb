# frozen_string_literal: true

class Folio::Console::Ui::InPlaceInputComponent < Folio::Console::ApplicationComponent
  def initialize(attribute:, record:, as: nil, cleave: false)
    @attribute = attribute
    @record = record
    @value = record.send(attribute)
    @cleave = cleave
    @textarea = !cleave && @record.class.columns_hash[attribute.to_s].type == :text
    @as = as
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

  def name
    "#{@as || @record.model_name.param_key}[#{@attribute}]"
  end
end

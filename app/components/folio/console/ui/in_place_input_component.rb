# frozen_string_literal: true

class Folio::Console::Ui::InPlaceInputComponent < Folio::Console::ApplicationComponent
  bem_class_name :compact

  def initialize(attribute:,
                 record:,
                 as: nil,
                 cleave: false,
                 autocomplete: nil,
                 value_prefix: nil,
                 value_line_clamp: nil,
                 f: nil,
                 data: nil,
                 textarea: nil,
                 compact: false)
    @attribute = attribute
    @record = record
    @value = record.send(attribute)
    @cleave = cleave
    @textarea = textarea || (!cleave && @record.class.columns_hash[attribute.to_s] && @record.class.columns_hash[attribute.to_s].type == :text)
    @as = as
    @autocomplete = f ? nil : autocomplete
    @value_prefix = value_prefix
    @value_line_clamp = value_line_clamp
    @f = f
    @data = data
    @compact = compact
  end

  def url
    @f ? nil : url_for([:console, @record])
  end

  def wrap_data
    stimulus_controller("f-c-ui-in-place-input",
                        action: {
                          "f-c-ui-in-place-input:setValue" => "setValueFromEvent",
                          "f-c-ui-ajax-input:success" => "onSuccess",
                          "f-c-ui-ajax-input:cancel" => "onCancel",
                          "f-c-ui-ajax-input:blur" => "onBlur",
                        },
                        values: {
                          editing: false,
                          has_autocomplete: !!@autocomplete,
                        }).merge(@data || {})
  end

  def name
    if @f
      @attribute
    else
      "#{@as || @record.model_name.param_key}[#{@attribute}]"
    end
  end
end

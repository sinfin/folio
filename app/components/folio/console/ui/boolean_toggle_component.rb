# frozen_string_literal: true

class Folio::Console::Ui::BooleanToggleComponent < Folio::Console::ApplicationComponent
  bem_class_name :label, :verbose

  def initialize(record:, attribute:, url: nil, disabled: false, label: nil, verbose: false, as: nil, confirm: false, class_name: nil)
    @record = record
    @attribute = attribute
    @disabled = disabled
    @label = label || verbose
    @verbose = verbose
    @as = as
    @confirm = confirm
    @url = url
    @class_name = class_name
  end

  def checked
    !!@record.try(@attribute)
  end

  def name
    "#{as}[#{@attribute}]"
  end

  def as
    @as || @record.class.model_name.param_key
  end

  def verbose_label(boolean)
    @record.class.human_attribute_name("#{@attribute}/#{boolean}")
  end

  def label_string
    if @label == true
      @record.class.human_attribute_name(@attribute)
    else
      @label
    end
  end

  def confirmation
    if @confirm.is_a?(String)
      @confirm
    elsif @confirm
      "true"
    end
  end

  def data
    stimulus_controller("f-c-ui-boolean-toggle", values: {
      url: url_with_default,
      confirmation:,
    }, classes: %w[loading])
  end

  def input_data
    {
      url:,
      confirmation:,
      action: "f-c-boolean-toggle#inputChange",
      "f-c-boolean-toggle-target" => "input",
    }.compact
  end

  def url_with_default
    @url || url_for([:console, @record, format: :json])
  end
end

# frozen_string_literal: true

class Dummy::Ui::BooleanToggleComponent < Folio::Console::ApplicationComponent
  bem_class_name :label, :verbose

  def initialize(record:,
                 attribute:,
                 url:,
                 disabled: false,
                 label: nil,
                 verbose: false,
                 as: nil,
                 confirm: false,
                 class_name: nil,
                 small_label: false)
    @record = record
    @attribute = attribute
    @disabled = disabled
    @label = label || small_label || verbose
    @verbose = verbose
    @as = as
    @confirm = confirm
    @url = url
    @class_name = class_name
    @small_label = small_label
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
    stimulus_controller("d-ui-boolean-toggle", values: {
      url: @url,
      confirmation:,
    }, classes: %w[loading])
  end
end

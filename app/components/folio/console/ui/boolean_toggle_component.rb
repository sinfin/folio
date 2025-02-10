# frozen_string_literal: true

class Folio::Console::Ui::BooleanToggleComponent < Folio::Console::ApplicationComponent
  bem_class_name :label, :verbose, :disabled, :off_label

  def initialize(record:,
                 attribute:,
                 f: nil,
                 url: nil,
                 disabled: false,
                 label: nil,
                 verbose: false,
                 off_label: nil,
                 as: nil,
                 confirm: false,
                 checked: false,
                 class_name: nil,
                 static: false,
                 small_label: false,
                 test_id: nil)
    @record = record
    @attribute = attribute
    @disabled = disabled
    @label = label || small_label || verbose
    @off_label = off_label
    @verbose = verbose
    @as = as
    @confirm = confirm
    @url = url
    @f = f
    @class_name = class_name
    @small_label = small_label
    @static = static || @f.present?
    @checked = checked || attribute_checked?
    @test_id = test_id
  end

  def attribute_checked?
    !!@record.try(@attribute)
  end

  def name
    if @static && !@attribute
      nil
    else
      "#{as}[#{@attribute}]"
    end
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
      static: @static
    }, classes: %w[loading]).merge(test_id: @test_id.presence)
  end

  def url_with_default
    unless @static
      @url || url_for([:console, @record, format: :json])
    end
  end
end

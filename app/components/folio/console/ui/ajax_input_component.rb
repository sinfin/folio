# frozen_string_literal: true

class Folio::Console::Ui::AjaxInputComponent < Folio::Console::ApplicationComponent
  def initialize(name:,
                 url:,
                 value:,
                 label: nil,
                 type: :string,
                 width: nil,
                 cleave: false,
                 method: "PATCH",
                 min: nil,
                 max: nil,
                 step: nil,
                 placeholder: nil,
                 affix: nil,
                 small_affix: nil,
                 textarea: false,
                 rows: nil)
    @name = name
    @url = url
    @type = type
    @value = value
    @width = width
    @label = label
    @cleave = cleave
    @method = method
    @min = min
    @max = max
    @step = step
    @placeholder = placeholder
    @affix = affix
    @small_affix = small_affix
    @textarea = textarea
    @rows = rows
  end

  def data
    stimulus_controller('f-c-ui-ajax-input', values: {
      url: @url,
      cleave: @cleave,
      original_value: @value,
      method: @method,
    })
  end

  def input_data
    stimulus_data(action: { keyup: :onKeyUp, change: :onKeyUp },
                  target: "input")
  end

  def formatted_value
    if @value
      if @cleave
        ActionController::Base.helpers.number_with_delimiter(@value, delimiter: " ")
      else
        @value
      end
    end
  end

  def input_tag
    h = {
      class: "form-control f-c-ui-ajax-input__input",
      name: @name,
      value: formatted_value,
      placeholder: @placeholder,
      disabled: !!@disabled,
      data: input_data,
      tag: :input
    }

    if @textarea
      h[:tag] = :textarea
      h[:rows] = @rows
      h[:class] += " f-c-ui-ajax-input__input--textarea"
      h[:data]["controller"] = "f-input-autosize"
    else
      h[:type] = "text"
      h[:min] = @min
      h[:step] = @step
    end

    h
  end
end

# frozen_string_literal: true

class Folio::Console::Ui::AjaxInputComponent < Folio::Console::ApplicationComponent
  def initialize(name:,
                 url:,
                 value:,
                 formatted_value: nil,
                 label: nil,
                 collection: nil,
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
                 disabled: false,
                 rows: nil)
    @name = name
    @url = url
    @value = value
    @formatted_value = formatted_value || value
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
    @disabled = disabled
    @rows = rows
    @collection = collection
  end

  def data
    stimulus_controller("f-c-ui-ajax-input", values: {
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
      disabled: !!@disabled,
      data: input_data,
    }

    if @collection
      h[:tag] = :select
      h[:class] = "form-select f-c-ui-ajax-input__input f-c-ui-ajax-input__input--select"
    else
      h[:tag] = :input
      h[:value] = formatted_value
      h[:placeholder] = @placeholder

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
    end

    h
  end
end

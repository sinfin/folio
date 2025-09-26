# frozen_string_literal: true

class Folio::Console::Ui::AjaxInputComponent < Folio::Console::ApplicationComponent
  def initialize(name:,
                 url:,
                 value:,
                 f: nil,
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
                 rows: 1,
                 force_cancel: false,
                 use_saved_indicator: true,
                 autocomplete: nil)
    @name = name
    @url = url
    @value = value
    @f = f
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
    @autocomplete = autocomplete
    @force_cancel = force_cancel
    @use_saved_indicator = use_saved_indicator
  end

  def data
    stimulus_controller("f-c-ui-ajax-input", values: {
      remote: @f.nil?,
      url: @f ? "" : @url,
      cleave: @cleave,
      original_value: @value,
      method: @method,
      use_saved_indicator: @use_saved_indicator,
    }, action: {
      "f-c-ui-ajax-input:setValue" => "setValueFromEvent",
    })
  end

  def input_data
    h = stimulus_data(action: {
                        "keyup" => "onKeyUp",
                        "keydown" => "onKeyDownAndPress",
                        "keypress" => "onKeyDownAndPress",
                        "change" => "onKeyUp",
                        "blur" => "onBlur",
                      },
                      target: "input")

    if @autocomplete
      values = if @autocomplete.is_a?(Array)
        { collection: @autocomplete }
      elsif @autocomplete.is_a?(String)
        { url: @autocomplete }
      end

      if values
        autocomplete_h = stimulus_controller("f-input-autocomplete",
                                             inline: true,
                                             values:)

        return stimulus_merge(h, autocomplete_h)
      end
    end

    h
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

  def f_input
    @f.input @name,
             as: @textarea ? :text : nil,
             wrapper: false,
             label: false,
             input_html: {
               class: input_tag[:class],
               disabled: input_tag[:disabled],
               data: input_tag[:data],
               placeholder: input_tag[:placeholder],
               rows: input_tag[:rows],
               value: input_tag[:value],
               min: input_tag[:min],
               step: input_tag[:step],
             }
  end

  def input_tag
    @input_tag ||= begin
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
end

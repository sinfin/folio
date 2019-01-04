# frozen_string_literal: true

class DatePickerInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    value = @builder.object.public_send(attribute_name) || Date.today
    input_html_options[:value] = case value
                                 when Date, Time, DateTime
                                   format = options[:format] || :medium
                                   value.strftime('%d/%m/%Y')
                                 else
                                   value.to_s
    end

    input_html_options[:class] ||= []
    input_html_options[:class] << 'folio-console-date-picker'

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_field(attribute_name, merged_input_options)
  end
end

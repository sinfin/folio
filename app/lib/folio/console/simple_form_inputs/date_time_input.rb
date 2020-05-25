# frozen_string_literal: true

SimpleForm::Inputs::DateTimeInput.class_eval do
  def input(wrapper_options = nil)
    value = @builder.object.public_send(attribute_name)

    if value.present?
      input_html_options[:value] = I18n.l(value, format: :console_short)
      # input_html_options['data-date'] = value
    end

    input_html_options[:class] ||= []
    input_html_options[:class] << 'folio-console-date-picker'

    type = @builder.object.class.type_for_attribute(attribute_name).type
    if type == :date
      input_html_options[:class] << 'folio-console-date-picker--date'
    else
      input_html_options[:class] << 'folio-console-date-picker--date-time'
    end

    input_html_options['data-toggle'] = 'datetimepicker'

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end

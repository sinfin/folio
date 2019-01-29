# frozen_string_literal: true

SimpleForm::Inputs::DateTimeInput.class_eval do
  def input(wrapper_options = nil)
    value = @builder.object.public_send(attribute_name) || Time.zone.now
    input_html_options[:value] = I18n.l(value, format: :short)

    input_html_options[:class] ||= []
    input_html_options[:class] << 'folio-console-date-picker'

    if value.is_a?(Date)
      input_html_options[:class] << 'folio-console-date-picker--date'
    else
      input_html_options[:class] << 'folio-console-date-picker--date-time'
    end

    input_html_options['data-toggle'] = 'datetimepicker'

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end

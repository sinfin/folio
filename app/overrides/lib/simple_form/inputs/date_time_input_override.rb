# frozen_string_literal: true

SimpleForm::Inputs::DateTimeInput.class_eval do
  def input(wrapper_options = nil)
    value = @builder.object.try(attribute_name)

    if value.present?
      input_html_options[:value] = I18n.l(value, format: :console_short)
    end

    if options[:atom_setting]
      input_html_classes << "f-c-js-atoms-placement-setting"
      input_html_options["data-atom-setting"] = options[:atom_setting]
    end

    input_html_options[:class] ||= []
    input_html_options[:class] << "f-input"

    type = @builder.object.class.respond_to?(:type_for_attribute) ? @builder.object.class.type_for_attribute(attribute_name).type : :date

    input_html_options[:class] << "f-input--date"

    if options[:calendar_on_top]
      input_html_options[:class] << "f-input--date-on-top"
    end

    if type != :date
      input_html_options[:class] << "f-input--date-time"
    end

    input_html_options["autocomplete"] = "off"
    input_html_options["data-toggle"] = "datetimepicker"
    input_html_options["data-sprite-url"] = ActionController::Base.helpers.image_path("folio/input/date_time/svg-sprite.svg")

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end

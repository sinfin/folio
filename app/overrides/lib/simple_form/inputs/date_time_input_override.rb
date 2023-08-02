# frozen_string_literal: true

SimpleForm::Inputs::DateTimeInput.class_eval do
  def input(wrapper_options = nil)
    value = @builder.object.try(attribute_name)

    if value.present?
      input_html_options[:value] = I18n.l(value, format: :console_short)
    end

    register_atom_settings


    type = @builder.object.class.respond_to?(:type_for_attribute) ? @builder.object.class.type_for_attribute(attribute_name).type : :date

    register_stimulus("f-input-date-time", {
      calendar_on_top: options[:calendar_on_top],
      type:,
      min: options[:min] ? I18n.l(options[:min].to_datetime, format: :console_short) : nil,
      max: options[:max] ? I18n.l(options[:max].to_datetime, format: :console_short) : nil,
      sprite_url: ActionController::Base.helpers.image_path("folio/input/date_time/svg-sprite.svg"),
    }.compact)

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end
end

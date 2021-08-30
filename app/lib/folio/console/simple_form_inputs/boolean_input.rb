# frozen_string_literal: true

SimpleForm::Inputs::BooleanInput.class_eval do
  def input(wrapper_options = nil)
    iho = input_html_options || {}

    if options[:atom_setting]
      iho[:class] = [iho[:class], "f-c-js-atoms-placement-setting"].flatten
      iho["data-atom-setting"] = options[:atom_setting]
    end

    merged_input_options = merge_wrapper_options(iho, wrapper_options)

    if nested_boolean_style?
      build_hidden_field_for_checkbox +
        template.label_tag(nil, class: boolean_label_class) {
          build_check_box_without_hidden_field(merged_input_options) +
            inline_label
        }
    else
      build_check_box(unchecked_value, merged_input_options)
    end
  end
end

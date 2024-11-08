# frozen_string_literal: true

# Please do not make direct changes to this file!
# This generator is maintained by the community around simple_form-bootstrap:
# https://github.com/rafaelfranca/simple_form-bootstrap
# All future development, tests, and organization should happen there.
# Background history: https://github.com/plataformatec/simple_form/issues/1561

# Uncomment this and change the path if necessary to include your own
# components.
# See https://github.com/plataformatec/simple_form#custom-components
# to know more about custom components.
# Dir[Rails.root.join('lib/components/**/*.rb')].each { |f| require f }

enable_validation = false
if enable_validation
  input_valid_class = "is-valid"
  group_valid_class = "form-group-valid"
else
  input_valid_class = nil
  group_valid_class = nil
end

# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  # Default class for buttons
  config.button_class = "btn btn-primary"

  # Define the default class of the input wrapper of the boolean input.
  config.boolean_label_class = "form-check-label"

  # How the label text should be generated altogether with the required text.
  config.label_text = lambda do |label, required, explicit_label|
    if required.present?
      tooltip_title = required.gsub(/<abbr title="([^"]+)">\*<\/abbr>/, '\1')

      if tooltip_title.present?
        "#{label} <abbr class=\"form-label__required\" data-controller=\"f-tooltip\" data-f-tooltip-placement-value=\"auto\"  data-f-tooltip-trigger-value=\"hover\" data-f-tooltip-title-value=\"#{tooltip_title}\" data-action=\"mouseenter->f-tooltip#mouseenter mouseleave->f-tooltip#mouseleave\">*</abbr>"
      else
        "#{label} <span class=\"form-label__required\">#{required}</span>"
      end
    else
      "<span class=\"form-label__tooltip\">#{label}</span>"
    end
  end

  # Define the way to render check boxes / radio buttons with labels.
  config.boolean_style = :inline

  # You can wrap each item in a collection of radio/check boxes with a tag
  config.item_wrapper_tag = :div

  # Defines if the default input wrapper class should be included in radio
  # collection wrappers.
  config.include_default_input_wrapper_class = false

  # CSS class to add for error notification helper.
  config.error_notification_class = "f-c-form-errors__notification"

  # Method used to tidy up errors. Specify any Rails Array method.
  # :first lists the first message for each field.
  # :to_sentence to list all errors for each field.
  config.error_method = :to_sentence

  # add validation classes to `input_field`
  if enable_validation
    config.input_field_error_class = "is-invalid"
    config.input_field_valid_class = "is-valid"
  end

  # vertical forms
  #
  # vertical default_wrapper
  config.wrappers :vertical_form, tag: "div", class: "form-group", error_class: "form-group-invalid", valid_class: group_valid_class do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label
    b.use :input, class: "form-control", error_class: "is-invalid", valid_class: input_valid_class
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint, wrap_with: { tag: "small", class: "form-text" }
    b.use :custom_html, wrap_with: { tag: "div", class: "form-group__custom-html" }
    b.use :flag, wrap_with: { tag: "div", class: "form-group__flag" }
  end

  # vertical input for boolean
  config.wrappers :vertical_boolean, tag: "fieldset", class: "form-group", error_class: "form-group-invalid", valid_class: group_valid_class do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :form_check_wrapper, tag: "div", class: "form-check" do |bb|
      bb.use :input, class: "form-check-input", error_class: "is-invalid", valid_class: input_valid_class
      bb.use :label, class: "form-check-label"
      bb.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
      bb.use :hint, wrap_with: { tag: "small", class: "form-text" }
    end
  end

  # vertical input for radio buttons and check boxes
  config.wrappers :vertical_collection, item_wrapper_class: "form-check", item_label_class: "form-check-label", tag: "fieldset", class: "form-group", error_class: "form-group-invalid", valid_class: group_valid_class do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :legend_tag, tag: "legend", class: "col-form-label pt-0" do |ba|
      ba.use :label_text
    end
    b.use :input, class: "form-check-input", error_class: "is-invalid", valid_class: input_valid_class
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback d-block" }
    b.use :hint, wrap_with: { tag: "small", class: "form-text" }
  end

  # vertical file input
  config.wrappers :vertical_file, tag: "div", class: "form-group", error_class: "form-group-invalid", valid_class: group_valid_class do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly
    b.use :label
    b.use :input, class: "form-control-file", error_class: "is-invalid", valid_class: input_valid_class
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint, wrap_with: { tag: "small", class: "form-text" }
  end

  # vertical multi select
  config.wrappers :vertical_multi_select, tag: "div", class: "form-group", error_class: "form-group-invalid", valid_class: group_valid_class do |b|
    b.use :html5
    b.optional :readonly
    b.use :label
    b.wrapper tag: "div", class: "d-flex flex-row justify-content-between align-items-center" do |ba|
      ba.use :input, class: "form-control", error_class: "is-invalid", valid_class: input_valid_class
    end
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback d-block" }
    b.use :hint, wrap_with: { tag: "small", class: "form-text" }
  end

  # vertical range input
  config.wrappers :vertical_range, tag: "div", class: "form-group", error_class: "form-group-invalid", valid_class: group_valid_class do |b|
    b.use :html5
    b.use :placeholder
    b.optional :readonly
    b.optional :step
    b.use :label
    b.use :input, class: "form-control-range", error_class: "is-invalid", valid_class: input_valid_class
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback d-block" }
    b.use :hint, wrap_with: { tag: "small", class: "form-text" }
  end

  # The default wrapper to be used by the FormBuilder.
  config.default_wrapper = :vertical_form

  # Custom wrappers for input types. This should be a hash containing an input
  # type as key and the wrapper that will be used for all inputs with specified type.
  config.wrapper_mappings = {
    boolean:       :vertical_boolean,
    check_boxes:   :vertical_collection,
    date:          :vertical_multi_select,
    datetime:      :vertical_multi_select,
    date_time:     :vertical_multi_select,
    file:          :vertical_file,
    radio_buttons: :vertical_collection,
    range:         :vertical_range,
    time:          :vertical_multi_select
  }

  # enable custom form wrappers
  # config.wrapper_mappings = {
  #   boolean:       :custom_boolean,
  #   check_boxes:   :custom_collection,
  #   date:          :custom_multi_select,
  #   datetime:      :custom_multi_select,
  #   file:          :custom_file,
  #   radio_buttons: :custom_collection,
  #   range:         :custom_range,
  #   time:          :custom_multi_select
  # }
end

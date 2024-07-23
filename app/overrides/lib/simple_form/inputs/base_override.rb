# frozen_string_literal: true

SimpleForm::Inputs::Base.class_eval do
  def register_stimulus(name, values: {}, wrapper: false)
    h = if wrapper
      options[:wrapper_html] ||= {}
    else
      input_html_options
    end

    if h["data-controller"]
      h["data-controller"] += " #{name}"
    else
      h["data-controller"] = name
    end

    if wrapper
      h[:class] ||= []
      h[:class] << "f-input-form-group" if h[:class].exclude?("f-input-form-group")
      h[:class] << "f-input-form-group--#{name.to_s.delete_prefix("f-input-form-group-")}"

      input_html_options["data-#{name}-target"] = "input"
    else
      input_html_classes << "f-input" if input_html_classes.exclude?("f-input")
      input_html_classes << "f-input--#{name.to_s.delete_prefix("f-input-")}"
    end

    values.each do |key, value|
      h["data-#{name}-#{key.to_s.tr('_', '-')}-value"] = value
    end
  end

  def register_atom_settings
    if options[:folio_label]
      input_html_classes << "f-c-js-atoms-placement-label"
    elsif options[:folio_perex]
      input_html_classes << "f-c-js-atoms-placement-perex"
    elsif options[:atom_setting]
      input_html_options[:class] ||= []
      input_html_options[:class] << "f-c-js-atoms-placement-setting"
      input_html_options["data-atom-setting"] = options[:atom_setting]
    end
  end
end

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
    if options[:folio_label] || options[:atom_setting] == :title
      input_html_options[:class] ||= []
      input_html_options[:class] << "f-c-js-atoms-placement-label"
    end

    if options[:folio_perex] || options[:atom_setting] == :perex
      input_html_options[:class] ||= []
      input_html_options[:class] << "f-c-js-atoms-placement-perex"
    end

    if options[:atom_setting]
      input_html_options[:class] ||= []
      input_html_options[:class] << "f-c-js-atoms-placement-setting"
      input_html_options["data-atom-setting"] = options[:atom_setting]
    end
  end

  def required_class
    if required_field?
      if options[:required].is_a?(String) || options[:required].is_a?(Symbol)
        "required required--#{options[:required]}"
      else
        :required
      end
    else
      :optional
    end
  end

  def self.translate_required_text(custom_key: nil)
    key = custom_key || :"required.text"
    I18n.t(key, scope: i18n_scope, default: I18n.t(:"required.text", scope: i18n_scope, default: "required"))
  end

  def label(wrapper_options = nil)
    custom_text = if options[:required].is_a?(String) || options[:required].is_a?(Symbol)
      original_title = self.class.translate_required_text
      new_title = self.class.translate_required_text(custom_key: :"required.text/#{options[:required]}")
      label_text.gsub(original_title, new_title)
                .gsub(">*</abbr>", "></abbr>")
                .html_safe
    else
      label_text
    end

    label_options = merge_wrapper_options(label_html_options, wrapper_options)

    if generate_label_for_attribute?
      @builder.label(label_target, custom_text, label_options)
    else
      template.label_tag(nil, custom_text, label_options)
    end
  end
end

# frozen_string_literal: true

SimpleForm::Inputs::Base.class_eval do
  def register_stimulus(name, opts = {})
    if input_html_options["data-controller"]
      input_html_options["data-controller"] += " #{name}"
    else
      input_html_options["data-controller"] = name
    end

    input_html_classes << "f-input" if input_html_classes.exclude?("f-input")
    input_html_classes << "f-input--#{name.to_s.delete_prefix("f-input-")}"

    opts.each do |opt, value|
      input_html_options["data-#{name}-#{opt.to_s.tr('_', '-')}-value"] = value
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

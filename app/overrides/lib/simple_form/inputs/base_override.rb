# frozen_string_literal: true

SimpleForm::Inputs::Base.class_eval do
  def register_stimulus(name, values: {}, outlets: [], action: nil, wrapper: false)
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
      h[:class] << name.to_s

      input_html_options["data-#{name}-target"] = "input"
    else
      input_html_classes << "f-input" if input_html_classes.exclude?("f-input")
      input_html_classes << "f-input--#{name.to_s.delete_prefix("f-input-")}"
    end

    values.each do |key, value|
      h["data-#{name}-#{key.to_s.tr('_', '-')}-value"] = value
    end

    if action
      if action.is_a?(String)
        if action.include?("#")
          h["data-action"] = action
        else
          h["data-action"] = "#{name}##{action}"
        end
      else
        action.each do |trigger, action_s|
          str = "#{trigger}->#{name}##{action_s}"

          if h["data-action"]
            h["data-action"] += " #{str}"
          else
            h["data-action"] = str
          end
        end
      end
    end

    if outlets.present?
      outlets.each do |class_name_same_as_controller_name|
        h["data-#{name}-#{class_name_same_as_controller_name}-outlet"] = ".#{class_name_same_as_controller_name}"
      end
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

  # respect changes in app/assets/javascripts/folio/input/url.js
  def register_url_input(json: true, wrapper_options: nil)
    register_stimulus("f-c-input-form-group-url",
                      values: { loaded: false, json: },
                      action: {
                        "f-c-input-form-group-url:edit" => "edit",
                        "f-c-input-form-group-url:remove" => "remove",
                      },
                      wrapper: true)

    if json
      options[:value] ||= (object.try(attribute_name) || {}).to_json
    end

    options[:custom_html] = <<~HTML.html_safe
      <div class="f-c-input-form-group-url__inner">
        <div class="f-c-input-form-group-url__loader-wrap">
          <div class="folio-loader folio-loader--small f-c-input-form-group-url__loader"></div>
        </div>
        <div class="f-c-input-form-group-url__control-bar-wrap"></div>
      </div>
    HTML

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_field(attribute_name, merged_input_options)
  end
end

# frozen_string_literal: true

Dir["#{Folio::Engine.root}/app/lib/folio/simple_form_components/*.rb"].each do |file|
  load file
end

SimpleForm.setup do |config|
  config.wrappers :with_flag, tag: "div", class: "form-group form-group--with-flag", error_class: "form-group-invalid" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly

    b.use :input, class: "form-control", error_class: "is-invalid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint,  wrap_with: { tag: "small", class: "form-text" }

    b.use :flag, wrap_with: { tag: "div", class: "form-group__flag" }
    b.use :custom_html, wrap_with: { tag: "div", class: "form-group__custom-html" }
  end

  config.wrappers :with_custom_html, tag: "div", class: "form-group form-group--with-custom-html", error_class: "form-group-invalid" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly

    b.use :input, class: "form-control", error_class: "is-invalid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint,  wrap_with: { tag: "small", class: "form-text" }

    b.use :custom_html, wrap_with: { tag: "div", class: "form-group__custom-html" }
  end

  config.wrappers :input_group, tag: "div", class: "input-group", error_class: "form-group-invalid" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly

    b.use :input, class: "form-control", error_class: "is-invalid"
    b.use :full_error, wrap_with: { tag: "div", class: "invalid-feedback" }
    b.use :hint,  wrap_with: { tag: "small", class: "form-text" }

    b.use :input_group_append, wrap_with: { tag: "div", class: "input-group-append" }
    b.use :custom_html, wrap_with: { tag: "div", class: "form-group__custom-html" }
  end
end

ActiveSupport.on_load(:action_view) do
  def simple_form_for(record, options = {}, &block)
    if options[:readonly] || @audited_audit
      options[:html] ||= {}
      options[:html][:class] ||= ""
      options[:html][:class] += " simple_form--readonly"
      options[:url] = "#readonly"
    end

    super(record, options, &block)
  end
end

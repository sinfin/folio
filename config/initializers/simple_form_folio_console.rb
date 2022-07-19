# frozen_string_literal: true

SimpleForm.setup do |config|
  config.wrappers :with_flag, tag: "div", class: "form-group form-group--with-flag", error_class: "text-danger has-danger" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly

    b.use :input, class: "form-control"
    b.use :error, wrap_with: { tag: "small", class: "form-text" }
    b.use :hint,  wrap_with: { tag: "small", class: "form-text" }

    b.use :flag, wrap_with: { tag: "div", class: "form-group__flag" }
  end
end

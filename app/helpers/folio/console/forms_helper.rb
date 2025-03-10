# frozen_string_literal: true

module Folio::Console::FormsHelper
  def publishable_inputs(f, additional_fields = nil, atom_setting: true)
    cell("folio/console/publishable_inputs",
         f,
         additional_fields:,
         atom_setting:).show.html_safe
  end

  def translated_inputs(f, key, *args)
    model = { f:, key:, args: }
    cell("folio/console/translated_inputs", model).show.html_safe
  end

  def translated_inputs_for_locales(f, key, locales, *args)
    model = { f:, key:, args: }
    cell("folio/console/translated_inputs",
         model,
         locales:).show.html_safe
  end

  def private_attachments_fields(f, options = {})
    render partial: "private_attachments", locals: options.merge(f:)
  end

  def link_to_remove_association(*args)
    key = args.first.is_a?(String) ? 2 : 1
    data = { confirm: t("folio.console.remove_confirmation") }

    if args[key].present? && args[key][:data].present?
      data.merge!(args[key][:data])
    end

    args[key] = (args[key] || {}).merge(data:)
    super(*args)
  end

  def togglable_fields(f, key, parent: false, label: nil, &block)
    content_tag(:div, class: "f-c-togglable-fields") do
      concat(f.check_box(key, class: "form-check-input f-c-togglable-fields__input"))
      concat(f.label(label || key, class: "form-check-label f-c-togglable-fields__label"))
      concat(content_tag(:div, class: parent ? "f-c-togglable-fields__parent" : "f-c-togglable-fields__content", &block))
    end
  end

  def togglable_fields_content(reverse: false, &block)
    if reverse
      class_name = "f-c-togglable-fields__content "\
                   "f-c-togglable-fields__content--reverse"
    else
      class_name = "f-c-togglable-fields__content"
    end

    content_tag(:div, class: class_name, &block)
  end

  def new_record_modal_toggle(klass, opts = {})
    cell("folio/console/new_record_modal", klass, opts).toggle.html_safe
  end

  def new_record_modal(klass, opts = {})
    content_for(:modals) do
      cell("folio/console/new_record_modal", klass, opts).show.html_safe
    end
  end

  def simple_form_for_with_atoms(model, opts = {}, &block)
    layout_code = model.class.try(:console_atoms_layout_code) ||
                  cookies[:f_c_atoms_layout_switch].presence ||
                  "horizontal"
    layout_class = "f-c-simple-form-with-atoms--layout-#{layout_code}"

    disabled_atoms_class = opts[:disable_atoms] ? "f-c-simple-form-with-atoms--disable-atoms" : nil
    audited_class = @audited_audit ? "f-c-simple-form-with-atoms--audited-audit" : nil

    expandable = true

    if model.class.try(:console_atoms_expandable) == false
      expanded_class = "f-c-simple-form-with-atoms--expanded-form f-c-simple-form-with-atoms--non-expandable"
      expandable = false
    elsif model.class.try(:console_atoms_expanded_settings) || audited_class
      expanded_class = "f-c-simple-form-with-atoms--expanded-form"
    else
      expanded_class = nil
    end

    opts[:html] ||= {}
    opts[:html][:class] ||= ""
    opts[:html][:class] = ["f-c-simple-form-with-atoms",
                           opts[:html][:class],
                           layout_class,
                           expanded_class,
                           disabled_atoms_class,
                           audited_class].compact.join(" ")

    form_footer_options = opts.delete(:form_footer_options) || {}

    render layout: "folio/console/partials/simple_form_with_atoms",
           locals: {
             model:,
             opts:,
             layout_code:,
             form_footer_options:,
             expandable:,
             audited_audit_active: @audited_audit.present?,
           },
           &block
  end

  def form_footer(f, opts = {})
    if f && f.object && f.object.persisted? && f.object.class.try(:use_preview_tokens?)
      share_preview = true

      content_for(:modals) do
        render(Folio::Console::SharePreviewModalComponent.new(record: f.object))
      end
    else
      share_preview = false
    end

    render(Folio::Console::Form::FooterComponent.new(f:,
                                                     preview_path: opts[:preview_path],
                                                     share_preview:))
  end
end

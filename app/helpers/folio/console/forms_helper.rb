# frozen_string_literal: true

module Folio::Console::FormsHelper
  def translated_inputs(f, key, *args)
    model = { f: f, key: key, args: args }
    cell('folio/console/translated_inputs', model).show.html_safe
  end

  def translated_inputs_for_locales(f, key, locales, *args)
    model = { f: f, key: key, args: args }
    cell('folio/console/translated_inputs',
         model,
         locales: locales).show.html_safe
  end

  def private_attachments_fields(f, options = {})
    render partial: 'private_attachments', locals: options.merge(f: f)
  end

  def link_to_remove_association(*args)
    key = args.first.is_a?(String) ? 2 : 1
    data = { confirm: t('folio.console.remove_confirmation') }

    if args[key].present? && args[key][:data].present?
      data.merge!(args[key][:data])
    end

    args[key] = (args[key] || {}).merge(data: data)
    super(*args)
  end

  def togglable_fields(f, key, parent: false, &block)
    content_tag(:div, class: 'f-c-togglable-fields') do
      concat(f.check_box(key, class: 'f-c-togglable-fields__input'))
      concat(f.label(key, class: 'f-c-togglable-fields__label'))
      concat(content_tag(:div, class: parent ? 'f-c-togglable-fields__parent' : 'f-c-togglable-fields__content', &block))
    end
  end

  def togglable_fields_content(reverse: false, &block)
    if reverse
      class_name = 'f-c-togglable-fields__content '\
                   'f-c-togglable-fields__content--reverse'
    else
      class_name = 'f-c-togglable-fields__content'
    end

    content_tag(:div, class: class_name, &block)
  end

  def new_record_modal_toggle(klass, opts = {})
    cell('folio/console/new_record_modal', klass, opts).toggle.html_safe
  end

  def new_record_modal(klass, opts = {})
    content_for(:modals) do
      cell('folio/console/new_record_modal', klass, opts).show.html_safe
    end
  end

  def simple_form_for_with_atoms(model, opts = {}, &block)
    layout_code = model.class.try(:console_atoms_layout_code) ||
                  cookies[:f_c_atoms_layout_switch].presence ||
                  'horizontal'
    layout_class = "f-c-simple-form-with-atoms--layout-#{layout_code}"

    if model.class.try(:console_atoms_expanded_settings)
      expanded_class = 'f-c-simple-form-with-atoms--expanded-form'
    else
      expanded_class = nil
    end

    opts[:html] ||= {}
    opts[:html][:class] ||= ''
    opts[:html][:class] = ['f-c-simple-form-with-atoms',
                           opts[:html][:class],
                           layout_class,
                           expanded_class].compact.join(' ')

    form_footer_options = opts.delete(:form_footer_options) || {}

    render layout: 'folio/console/partials/simple_form_with_atoms',
           locals: {
             model: model,
             opts: opts,
             layout_code: layout_code,
             form_footer_options: form_footer_options,
           },
           &block
  end
end

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
    opts[:html] ||= {}
    opts[:html][:class] ||= ''
    opts[:html][:class] = "#{opts[:html][:class]} f-c-simple-form-with-atoms"

    simple_form_for(model, opts) do |f|
      concat(
        content_tag(:div, class: 'f-c-simple-form-with-atoms__preview') do
          concat(content_tag(:div,
                             cell('folio/console/atom_previews', f.object.atoms).show.html_safe,
                             class: 'f-c-simple-form-with-atoms__preview-inner'))
          concat(content_tag(:span, nil, class: 'folio-loader'))
        end
      )
      content_tag(:div, yield(f), class: 'f-c-simple-form-with-atoms__form')
    end
  end
end

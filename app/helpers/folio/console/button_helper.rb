# frozen_string_literal: true

module Folio
  module Console::ButtonHelper
    def new_button(path, opts = { label: nil })
      label = opts.delete(:label) || t('folio.console.breadcrumbs.actions.add')
      ico = icon 'plus', label

      opts.reverse_merge!(class: 'btn btn-success')

      link_to(ico, path, opts)
    end

    def edit_button(record, path, opts = {})
      ico = icon 'edit'

      opts.reverse_merge!(
        class: 'btn btn-secondary',
        title: t('folio.console.breadcrumbs.actions.edit')
      )

      link_to(ico, path, opts)
    end

    def view_button(path, opts = {})
      ico = icon('eye')

      opts.reverse_merge!(
        class: 'btn btn-info',
        target: '_blank',
      )

      link_to(ico, path, opts)
    end

    def custom_icon_button(path, icon_name = 'eye', opts = {})
      opts.reverse_merge!(class: "btn btn-#{opts[:color] || 'info'}")

      link_to(icon(icon_name), path, opts).html_safe
    end

    def delete_button(record, path, opts = {}, text: false)
      name = record.try(:to_label) ||
             record.try(:full_title) ||
             record.try(:title)
      question = t('folio.console.really_delete', title: name)

      if text
        content = t('folio.console.delete')
      else
        content = icon 'trash'
      end

      opts.reverse_merge!(
        'data-confirm': question,
        method: :delete,
        class: 'btn btn-danger',
        title: t('folio.console.breadcrumbs.actions.delete')
      )

      link_to(content, path, opts)
    end
  end
end

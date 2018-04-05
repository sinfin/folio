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

    def delete_button(record, path, opts = {}, text: false)
      name = record.try(:full_title) || record.title
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

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

      opts.reverse_merge!(class: 'btn btn-secondary')

      link_to(ico, path, opts)
    end

    def delete_button(record, path, opts = {})
      name = record.try(:full_title) || record.title
      question = t('folio.console.really_delete', title: name)

      ico = icon 'trash'

      opts.reverse_merge!('data-confirm': question,
                          method: :delete,
                          class: 'btn btn-danger')

      link_to(ico, path, opts)
    end

    def destroy_button(f, label)
      link_to '#', class: 'btn btn-danger destroy', role: 'button' do
        [
          label,
          f.hidden_field(:_destroy, value: 0)
        ].join('').html_safe
      end
    end
  end
end

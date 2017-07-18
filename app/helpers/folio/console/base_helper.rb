# frozen_string_literal: true

module Folio
  module Console::BaseHelper
    def icon(name, title = nil)
      i = "<i class='fa fa-#{name}'></i>"
      [i, title].compact.join(' ').html_safe
    end

    def delete_button(record, path, opts = { label: 'Smazat' })
      name = record.try(:full_title) || record.title
      question = t('really_delete', title: name)
      ico = icon 'trash', opts.delete(:label)

      opts.reverse_merge!('data-confirm': question,
                          method: :delete,
                          class: 'btn btn-danger pull-right')

      link_to(ico, path, opts).html_safe
    end
  end
end

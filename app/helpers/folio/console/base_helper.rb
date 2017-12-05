# frozen_string_literal: true

module Folio
  module Console::BaseHelper
    def icon(name, title = nil)
      i = "<i class='fa fa-#{name}'></i>"
      [i, title].compact.join(' ').html_safe
    end

    def featured_button(bool)
      button_tag(class: 'btn btn-sm btn-transparent node') do
        featured_icon(bool)
      end
    end

    def published_button(bool)
      button_tag(class: 'btn btn-sm btn-transparent node') do
        on_off_icon(bool)
      end
    end

    def new_button(path, opts = { label: 'New' })
      ico = icon 'plus', opts.delete(:label)

      opts.reverse_merge!(class: 'btn btn-success pull-right')

      link_to(ico, path, opts).html_safe
    end

    def edit_button(record, path, opts = { label: 'Edit' })
      name = record.try(:full_title) || record.title
      ico = icon 'edit', opts.delete(:label)

      opts.reverse_merge!(class: 'btn btn-info pull-right')

      link_to(ico, path, opts).html_safe
    end

    def delete_button(record, path, opts = { label: 'Delete' })
      name = record.try(:full_title) || record.title
      question = t('folio.console.really_delete', title: name)
      ico = icon 'trash', opts.delete(:label)

      opts.reverse_merge!('data-confirm': question,
                          method: :delete,
                          class: 'btn btn-danger pull-right')

      link_to(ico, path, opts).html_safe
    end

    def destroy_button(f, label)
      link_to '#', class: 'btn btn-danger destroy', role: 'button' do
        [
          label,
          f.hidden_field(:_destroy, value: 0)
        ].join('').html_safe
      end
    end

    def locale_to_label(locale, short: false)
      c = ISO3166::Country.new(Folio::LANGUAGES[locale.to_sym])

      if short
        "#{locale} #{c.try(:emoji_flag)}"
      else
        "#{t("folio.locale.languages.#{locale}")} #{c.try(:emoji_flag)}"
      end
    end
  end
end

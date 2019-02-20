# frozen_string_literal: true

module Folio
  module Console::FormsHelper
    def console_form_atoms(f)
      render partial: 'atoms', locals: { f: f }
    end

    def translated_inputs(f, key, *args)
      cell('folio/console/translated_inputs', f: f, key: key, args: args).show.html_safe
    end

    def private_attachments_fields(f)
      render partial: 'private_attachments', locals: { f: f }
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
  end
end

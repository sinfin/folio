# frozen_string_literal: true

module Folio::Console::FormsHelper
  def console_form_atoms(f)
    render partial: 'atoms', locals: { f: f }
  end

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
end

# frozen_string_literal: true

class Folio::Console::TranslatedInputsCell < Folio::ConsoleCell
  def f
    model[:f]
  end

  def key
    model[:key]
  end

  def compact
    args_hash = model[:args]&.find { |arg| arg.is_a?(Hash) && arg.key?(:compact) }
    args_hash ? args_hash[:compact] : true
  end

  def args
    if translations.size == 1
      label_hash = { label: f.object.class.human_attribute_name(key) }

      if model[:args].present? && first = model[:args].first.presence
        [label_hash.merge(first)] + model[:args][1..-1]
      else
        [label_hash]
      end
    else
      model[:args]
    end
  end

  def translations
    @translations ||= if options[:locales]
      options[:locales]
    elsif ::Rails.application.config.folio_using_traco
      current_site.locales
    else
      []
    end
  end

  def args_with_locale(locale)
    common = { wrapper: :with_flag, flag: locale, hint: false, locale: }

    if args.present? && first = args.first.presence
      [first.merge(common)] + args[1..-1]
    else
      [common]
    end
  end
end

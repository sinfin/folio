# frozen_string_literal: true

class Folio::Console::TranslatedInputsCell < Folio::ConsoleCell
  def f
    model[:f]
  end

  def key
    model[:key]
  end

  def args
    model[:args]
  end

  def translations
    @translations ||= begin
      if options[:locales]
        options[:locales]
      elsif ::Rails.application.config.folio_using_traco
        I18n.available_locales
      else
        nil
      end
    end
  end

  def args_with_locale(locale)
    common = { wrapper: :with_flag, flag: locale, hint: false, locale: locale }

    if args.present? && first = args.first.presence
      [
        first.merge(common)
      ] + args[1..-1]
    else
      [common]
    end
  end
end

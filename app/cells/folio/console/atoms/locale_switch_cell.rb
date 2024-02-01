# frozen_string_literal: true

class Folio::Console::Atoms::LocaleSwitchCell < Folio::ConsoleCell
  def locales
    if model.class.try(:atom_locales)
      filtered = model.class.atom_locales & current_site.locales_as_sym

      if filtered.present?
        filtered
      else
        [I18n.default_locale]
      end
    else
      [I18n.default_locale]
    end
  end

  def default_locale
    options[:selected].presence || I18n.default_locale
  end

  def active_class(locale)
    if locale.nil? || locale.to_sym == default_locale
      "f-c-atoms-locale-switch__button--active"
    end
  end
end

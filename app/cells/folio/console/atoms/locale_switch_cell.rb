# frozen_string_literal: true

class Folio::Console::Atoms::LocaleSwitchCell < Folio::ConsoleCell
  include Folio::Console::FlagHelper

  def locales
    model.class.try(:atom_locales) || [I18n.default_locale]
  end

  def active_class(locale)
    if locale.nil? || locale.to_sym == I18n.default_locale
      'f-c-atoms-locale-switch__button--active'
    end
  end
end

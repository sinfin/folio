# frozen_string_literal: true

class Folio::Console::Atoms::LocaleSwitchCell < Folio::ConsoleCell
  include Folio::Console::FlagHelper

  def locales
    model.class.try(:atom_locales) || [I18n.default_locale]
  end

  def active(locale)
    locale.nil? || locale.to_sym == I18n.default_locale
  end
end

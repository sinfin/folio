# frozen_string_literal: true

class Folio::Console::AtomsFormHeaderCell < Folio::ConsoleCell
  include Folio::Console::FlagHelper

  def locales
    model.class.try(:atom_locales) || [I18n.default_locale]
  end
end

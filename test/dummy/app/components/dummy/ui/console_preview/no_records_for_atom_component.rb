# frozen_string_literal: true

class Dummy::Ui::ConsolePreview::NoRecordsForAtomComponent < ApplicationComponent
  def initialize(atom:)
    @atom = atom
  end

  def message
    if I18n.locale == :cs
      "Žádné publikované záznamy. Veřejně nebude zobrazen."
    else
      "No published records. Will not be shown publicly."
    end
  end
end

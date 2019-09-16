# frozen_string_literal: true

class Folio::Console::Atoms::PreviewsCell < Folio::ConsoleCell
  include Folio::AtomsHelper

  def show
    render if model.is_a?(Hash)
  end

  def controls
    @controls ||= render(:_controls)
  end

  def insert
    @insert ||= render(:_insert)
  end

  def sorted_types
    Folio::Atom.types.sort_by do |klass|
      I18n.transliterate(klass.model_name.human)
    end
  end
end

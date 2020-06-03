# frozen_string_literal: true

class Folio::Console::Atoms::PreviewsCell < Folio::ConsoleCell
  include Folio::AtomsHelper

  class_name 'f-c-atoms-previews', :non_interactive

  def show
    render if model.is_a?(Hash)
  end

  def controls
    @controls ||= render(:_controls)
  end

  def insert
    @insert ||= render(:_insert)
  end

  def label_perex_controls
    @label_perex_controls ||= render(:_label_perex_controls)
  end

  def sorted_types
    Folio::Atom.types
               .reject { |klass| klass.molecule_secondary }
               .sort_by { |klass| I18n.transliterate(klass.model_name.human) }
  end

  def locale_hidden(locale)
    return false if locale.nil?
    locale.to_sym != default_locale
  end

  def default_locale
    options[:default_locale].try(:to_sym) || I18n.default_locale
  end

  def atom_cell(atom)
    opts = (atom.cell_options.presence || {}).merge(console_preview: true)
    cell(atom.class.cell_name, atom, opts)
  end
end

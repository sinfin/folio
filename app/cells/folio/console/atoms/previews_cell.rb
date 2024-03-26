# frozen_string_literal: true

class Folio::Console::Atoms::PreviewsCell < Folio::ConsoleCell
  include Folio::AtomsHelper

  class_name "f-c-atoms-previews", :non_interactive

  def show
    render if model.is_a?(Hash)
  end

  def controls
    @controls ||= render(:_controls)
  end

  def insert(before: nil, after: nil)
    if options[:non_interactive]
      nil
    else
      @insert_inner ||= render(:_inner_insert)

      class_name_base = "f-c-atoms-previews__insert"
      class_name = class_name_base
      class_name += " #{class_name_base}--first" if after.nil?
      class_name += " #{class_name_base}--last" if before.nil?

      content_tag(:div,
                  @insert_inner,
                  class: class_name,
                  "data-before" => before,
                  "data-after" => after)
    end
  end

  def label_perex_controls
    @label_perex_controls ||= render(:_label_perex_controls)
  end

  def sorted_types
    ary = Folio::Atom.klasses_for(klass: options[:klass])
                     .reject { |klass| klass.molecule_secondary }

    ary = ary.sort_by { |klass| I18n.transliterate(klass.model_name.human) }

    tmp = {}

    ary.each do |klass|
      tmp[klass.console_insert_row] ||= []
      tmp[klass.console_insert_row] << klass
    end

    h = {}

    tmp.keys.sort.each { |key| h[key] = tmp[key] }

    h
  end

  def locale_hidden(locale)
    return false if locale.nil?
    locale.to_sym != default_locale
  end

  def default_locale
    options[:default_locale].try(:to_sym) || current_site.locale || ::Rails.application.config.folio_console_locale
  end

  def atom_additional_options
    { console_preview: true, console_preview_settings_param: options[:settings_param] }
  end

  def splittable_class_name(atoms, atom, atom_index)
    field = atom.class.splittable_by_attribute

    if field && atoms[atom_index + 1] && atoms[atom_index + 1].class.splittable_by_attribute == field
      "f-c-atoms-previews__preview--splittable-can-be-joined"
    end
  end

  def render_molecule(atoms)
    atom_class = atoms.first.class

    if atom_class.molecule_component_class
      capture { render_view_component(atom_class.molecule_component_class.new(atoms:, atom_options: atom_additional_options)) }
    else
      cell(atom_class.molecule_cell_name,
           atoms,
           atom_additional_options)
    end
  end

  def render_atom(atom)
    atom_class = atom.class

    if atom_class.component_class
      capture { render_view_component(atom_class.component_class.new(atom:, atom_options: atom_additional_options)) }
    else
      opts = (atom.cell_options.presence || {}).merge(atom_additional_options)
      cell(atom_class.cell_name, atom, opts)
    end
  end
end

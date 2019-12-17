# frozen_string_literal: true

module Folio::Atom
  def self.types
    Folio::Atom::Base.recursive_subclasses(include_self: false)
  end

  def self.structures
    str = {}
    Folio::Atom::Base.recursive_subclasses(include_self: false).each do |klass|
      structure = {}

      klass::STRUCTURE.each do |key, value|
        structure[key] = {
          label: klass.human_attribute_name(key),
          hint: I18n.t("simple_form.hints.#{klass.name.underscore}.#{key}", default: nil),
          type: value,
        }

        if value.is_a?(Array)
          structure[key][:type] = 'collection'
          structure[key][:collection] = value
        end
      end

      attachments = klass::ATTACHMENTS.map do |key|
        reflection = klass.reflections[key.to_s]
        plural = reflection.through_reflection.is_a?(ActiveRecord::Reflection::HasManyReflection)
        file_type = reflection.source_reflection.options[:class_name]

        {
          file_type: file_type,
          key: "#{klass.reflections[key.to_s].options[:through]}_attributes",
          label: klass.human_attribute_name(key),
          plural: plural,
        }
      end

      associations = {}
      klass::ASSOCIATIONS.each do |key, model_class_names|
        url = Folio::Engine.routes
                           .url_helpers
                           .url_for([:selectize,
                                     :console,
                                     :api,
                                     :autocomplete,
                                     class_names: model_class_names.join(','),
                                     only_path: true])

        associations[key] = {
          hint: I18n.t("simple_form.hints.#{klass.name.underscore}.#{key}", default: nil),
          label: klass.human_attribute_name(key),
          url: url,
        }
      end

      str[klass.to_s] = {
        associations: associations,
        attachments: attachments,
        hint: I18n.t("simple_form.hints.#{klass.name.underscore}.base", default: nil),
        structure: structure,
        title: klass.model_name.human,
        molecule: klass.molecule_cell_name,
        molecule_singleton: klass.molecule_singleton,
        molecule_secondary: klass.molecule_secondary,
      }
    end
    str
  end

  def self.strong_params
    keys = []
    Folio::Atom::Base.recursive_subclasses(include_self: false).each do |klass|
      keys += klass::STRUCTURE.keys
      keys += klass::ASSOCIATIONS.keys.map { |k| { k => [:id, :type] } }
    end
    keys.uniq
  end

  def self.atoms_in_molecules(atoms)
    molecules = []

    atoms.each_with_index do |atom, index|
      molecule = atom.class.molecule.presence ||
                 atom.class.molecule_cell_name.presence

      if index != 0 && molecule == molecules.last.first
        # same kind of molecule
        molecules.last.last << atom
      else
        # different kind of molecule
        molecules << [molecule, [atom]]
      end
    end

    molecules
  end

  def self.atom_image_placements(atoms)
    images = []

    atoms.each do |atom|
      images << atom.cover_placement
      images += atom.image_placements.to_a
    end

    images.compact
  end

  def self.association_to_h(record, show_model_names: false)
    label = [
      show_model_names ? record.model_name.human : nil,
      record.to_console_label,
    ].compact.join(' / ')

    {
      id: record.id,
      type: record.class.name,
      text: label,
      label: label,
      value: Folio::Console::StiHelper.sti_record_to_select_value(record)
    }
  end
end

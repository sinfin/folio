# frozen_string_literal: true

module Folio::Atom
  extend Folio::Console::StiHelper

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
          type: value
        }
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
        records = model_class_names.flat_map do |model_class_name|
          model_class = model_class_name.to_s.constantize
          klass.scoped_model_resource(model_class)
               .map { |record| { id: record.id, type: record.class.name, label: record.to_label } }
               .sort_by { |h| I18n.transliterate(h[:label]) }
        end

        associations[key] = {
          hint: I18n.t("simple_form.hints.#{klass.name.underscore}.#{key}", default: nil),
          label: klass.human_attribute_name(key),
          records: records,
        }
      end

      str[klass.to_s] = {
        associations: associations,
        attachments: attachments,
        hint: I18n.t("simple_form.hints.#{klass.name.underscore}.base", default: nil),
        structure: structure,
        title: klass.model_name.human,
      }
    end
    str
  end

  def self.strong_params
    keys = []
    Folio::Atom::Base.recursive_subclasses(include_self: false).each do |klass|
      keys += klass::STRUCTURE.keys
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
end

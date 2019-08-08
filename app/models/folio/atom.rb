# frozen_string_literal: true

module Folio::Atom
  extend Folio::Console::StiHelper

  def self.types
    Folio::Atom::Base.recursive_subclasses(include_self: false)
  end

  def self.structures
    str = {}
    Folio::Atom::Base.recursive_subclasses(include_self: false).each do |klass|
      h = {}

      klass::STRUCTURE.each do |key, value|
        h[key] = {
          label: klass.human_attribute_name(key),
          hint: I18n.t("simple_form.hints.#{klass.name.underscore}.#{key}", default: nil),
          validators: klass.validators_on(key).map do |validator|
            { 'class' => validator.class.to_s, 'options' => validator.options }
          end
        }

        if value.is_a?(Array)
          show_model_names = value.size > 1
          h[key][:type] = :relation
          h[key][:collection] = value.flat_map do |model_class_name|
            model_class = model_class_name.constantize
            sti_records_for_select(klass.scoped_model_resource(model_class),
                                   show_model_names: show_model_names)
          end.sort_by { |ary| I18n.transliterate(ary.first) }
        elsif value == :redactor
          h[key][:type] = :richtext
        else
          h[key][:type] = value
        end
      end

      attachments = klass::ATTACHMENTS.map do |key|
        reflection = klass.reflections[key.to_s]
        plural = reflection.through_reflection.is_a?(ActiveRecord::Reflection::HasManyReflection)
        file_type = reflection.source_reflection.options[:class_name]

        {
          key: "#{klass.reflections[key.to_s].options[:through]}_attributes",
          label: klass.human_attribute_name(key),
          plural: plural,
          file_type: file_type,
        }
      end

      str[klass.to_s] = {
        attachments: attachments,
        structure: h,
        title: klass.model_name.human,
        hint: I18n.t("simple_form.hints.#{klass.name.underscore}.base", default: nil)
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

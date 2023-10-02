# frozen_string_literal: true

module Folio::Atom
  def self.klasses_for(klass:)
    ary = if klass.atom_class_names_whitelist
      klass.atom_class_names_whitelist.map(&:constantize)
    else
      Folio::Atom::Base.recursive_subclasses(include_self: false, exclude_abstract: true)
    end

    ary.select { |atom_klass| atom_klass.valid_for_placement_class?(klass) }
  end

  def self.structures_for(klass:)
    str = {}

    klasses_for(klass:).each do |klass|
      structure = {}

      klass::STRUCTURE.each do |key, value|
        structure[key] = {
          label: klass.human_attribute_name(key),
          hint: I18n.t("simple_form.hints.#{klass.name.underscore}.#{key}", default: nil).try(:html_safe),
          type: value,
          character_counter: value == :text,
          default_values: klass.default_atom_values[key],
          splittable: klass.molecule_cell_name ? nil : klass.splittable_by_attribute == key,
        }

        if value.is_a?(Array)
          structure[key][:type] = "collection"
          structure[key][:collection] = value.map do |option|
            [
              klass.human_attribute_name("#{key}/#{option.presence || 'nil'}"),
              option
            ]
          end
        end
      end

      attachments = klass::ATTACHMENTS.map do |key|
        reflection = klass.reflections[key.to_s]
        plural = reflection.through_reflection.is_a?(ActiveRecord::Reflection::HasManyReflection)
        file_type = reflection.source_reflection.options[:class_name]
        file_klass = file_type.constantize
        files_url = Rails.application.config.folio_atom_files_url.call(file_klass)

        {
          file_type:,
          files_url:,
          key: "#{klass.reflections[key.to_s].options[:through]}_attributes",
          label: klass.human_attribute_name(key),
          human_type: file_klass.try(:human_type) || "document",
          plural:,
        }
      end

      associations = {}
      klass::ASSOCIATIONS.each do |key, association|
        if association.is_a?(Hash)
          class_names = association[:klasses].join(",")
          scope = association[:scope]
          order_scope = association[:order_scope]
        else
          class_names = association.join(",")
          scope = nil
          order_scope = nil
        end

        url = Folio::Engine.routes
                           .url_helpers
                           .url_for([:react_select,
                                     :console,
                                     :api,
                                     :autocomplete,
                                     class_names:,
                                     scope:,
                                     order_scope:,
                                     only_path: true])

        associations[key] = {
          hint: I18n.t("simple_form.hints.#{klass.name.underscore}.#{key}", default: nil).try(:html_safe),
          label: klass.human_attribute_name(key),
          url:,
        }
      end

      str[klass.to_s] = {
        associations:,
        attachments:,
        hint: I18n.t("simple_form.hints.#{klass.name.underscore}.base", default: nil).try(:html_safe),
        structure:,
        form_layout: klass::FORM_LAYOUT,
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
    Folio::Atom::Base.recursive_subclasses(include_self: false, exclude_abstract: true).each do |klass|
      keys += klass::STRUCTURE.keys
      keys += klass::ASSOCIATIONS.keys.map { |k| { k => [:id, :type] } }
    end
    keys.uniq
  end

  def self.atoms_in_molecules(atoms)
    molecules = []

    atoms.each_with_index do |atom, index|
      molecule = atom.class.molecule_component_class ||
                 atom.class.molecule.presence ||
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
    ].compact.join(" / ")

    {
      id: record.id,
      type: record.class.name,
      text: label,
      label:,
      value: Folio::Console::StiHelper.sti_record_to_select_value(record)
    }
  end
end

# frozen_string_literal: true

module Folio::Atom
  def self.types
    Folio::Atom::Base.recursive_subclasses
  end

  def self.text_fields
    @text_fields ||= begin
      if Rails.application.config.folio_using_traco
        text_fields = []
        Folio::Atom::Base.column_names.each do |column|
          if column =~ /\A(title|content|perex)_/
            text_fields << column.to_sym
          end
        end
        text_fields
      else
        [:title, :content, :perex]
      end
    end
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
end

if Rails.env.development?
  Dir[
    Folio::Engine.root.join('app/models/folio/atom/**/*.rb'),
    Rails.root.join('app/models/**/atom/**/*.rb')
  ].each do |file|
    require_dependency file
  end
end

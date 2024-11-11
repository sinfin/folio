# frozen_string_literal: true

module Folio::AtomsHelper
  def render_atom(atom, atom_options: {})
    if atom.class.component_class
      if self.is_a?(Folio::ApplicationCell)
        capture { render_view_component(atom.class.component_class.new(atom:, atom_options:)) }
      else
        capture { render(atom.class.component_class.new(atom:, atom_options:)) }
      end
    elsif atom.class.cell_name
      cell(atom.class.cell_name,
           atom,
           atom.cell_options.present? ? atom.cell_options.merge(atom_options) : atom_options)
    else
      render "folio/atoms/#{atom.partial_name}", data: atom
    end
  end

  def render_molecule(molecule, atoms, atom_options: {})
    if atoms.present?
      if molecule.is_a?(String)
        cell(molecule,
             atoms,
             atom_options)
      elsif molecule < ViewComponent::Base
        if self.is_a?(Folio::ApplicationCell)
          capture { render_view_component(molecule.new(atoms:, atom_options:)) }
        else
          capture { render(molecule.new(atoms:, atom_options:)) }
        end
      else
        cell(molecule.cell_name,
             atoms,
             molecule.cell_options.present? ? molecule.cell_options.merge(atom_options) : atom_options)
      end
    end
  end

  def render_atoms(atoms, only: [], except: [], atom_options: {}, cover_placements: true)
    if cover_placements && !atom_options[:cover_placements]
      atom_options = atom_options.merge(cover_placements: cover_placements_for_atoms(atoms))
    end

    atoms.filter_map do |atom|
      next if only.present? && !only.include?(atom.class)
      next if except.present? && except.include?(atom.class)

      render_atom(atom, atom_options:)
    end.join("").html_safe
  end

  def render_atoms_in_molecules(atoms_in_molecules, only: [], except: [], atom_options: {}, cover_placements: true)
    if cover_placements
      atoms = []
      atoms_in_molecules.each { |_molecule, molecule_atoms| atoms += molecule_atoms }
      atom_options = atom_options.merge(cover_placements: cover_placements_for_atoms(atoms))
    end

    atoms_in_molecules.filter_map do |molecule, atoms|
      if only.present?
        atoms = atoms.select { |a| only.include?(a.class) }
      end

      if except.present?
        atoms = atoms.select { |a| except.exclude?(a.class) }
      end

      next if atoms.blank?

      if molecule.present?
        render_molecule(molecule, atoms, atom_options:)
      else
        render_atoms(atoms, atom_options:)
      end
    end.join("").html_safe
  end

  def cover_placements_for_atoms(atoms)
    placement = []

    atoms.each do |atom|
      if atom.class::ATTACHMENTS.include?(:cover)
        placement << atom
      end
    end

    if placement.present?
      Folio::FilePlacement::Cover.where(placement:)
                                 .includes(:file)
                                 .index_by(&:placement_id)
    else
      {}
    end
  end
end

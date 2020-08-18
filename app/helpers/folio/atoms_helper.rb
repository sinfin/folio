# frozen_string_literal: true

module Folio::AtomsHelper
  def render_atoms(atoms, only: [], except: [])
    atoms.map do |atom|
      next if only.present? && !only.include?(atom.class)
      next if except.present? && except.include?(atom.class)

      if atom.class.cell_name
        cell(atom.class.cell_name, atom, atom.cell_options.presence || {})
      else
        render "folio/atoms/#{atom.partial_name}", data: atom
      end
    end.compact.join("").html_safe
  end

  def render_atoms_in_molecules(atoms_in_molecules, only: [], except: [])
    atoms_in_molecules.map do |molecule, atoms|
      if only.present?
        atoms = atoms.select { |a| only.include?(a.class) }
      end

      if except.present?
        atoms = atoms.select { |a| except.exclude?(a.class) }
      end

      next if atoms.blank?

      if molecule.present?
        if atoms.present?
          if molecule.is_a?(String)
            cell(molecule,
                 atoms)
          else
            cell(molecule.cell_name,
                 atoms,
                 molecule.cell_options.presence || {})
          end
        end
      else
        render_atoms(atoms)
      end
    end.compact.join("").html_safe
  end
end

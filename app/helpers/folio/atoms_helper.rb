# frozen_string_literal: true

module Folio::AtomsHelper
  def render_atoms(atoms, only: [], except: [], atom_options: {})
    atoms.filter_map do |atom|
      next if only.present? && !only.include?(atom.class)
      next if except.present? && except.include?(atom.class)

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
    end.join("").html_safe
  end

  def render_atoms_in_molecules(atoms_in_molecules, only: [], except: [], atom_options: {})
    atoms_in_molecules.filter_map do |molecule, atoms|
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
      else
        render_atoms(atoms, atom_options:)
      end
    end.join("").html_safe
  end
end

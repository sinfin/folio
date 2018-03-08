# frozen_string_literal: true

module Folio
  module AtomsHelper
    def render_atoms(atoms, only: [], except: [])
      ordered = atoms.respond_to?(:ordered) ? atoms.ordered : atoms

      ordered.map do |atom|
        next if only.present? && !only.include?(atom.class)
        next if except.present? && except.include?(atom.class)

        if atom.cell_name
          cell(atom.cell_name, atom.data)
        else
          render "folio/atoms/#{atom.partial_name}", data: atom.data
        end
      end.compact.join('').html_safe
    end
  end
end

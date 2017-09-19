# frozen_string_literal: true

module Folio
  module AtomsHelper
    def render_atoms(atoms)
      atoms.map do |atom|
        if atom.cell_name
          cell(atom.cell_name, atom.data)
        else
          render "folio/atoms/#{atom.partial_name}", locals: { data: atom.data }
        end
      end.join('').html_safe
    end
  end
end

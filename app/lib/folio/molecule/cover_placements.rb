# frozen_string_literal: true

module Folio::Molecule::CoverPlacements
  def molecule_cover_placements
    @molecule_cover_placements ||= Folio::FilePlacement::Cover.where(placement: @atoms)
                                                              .includes(:file)
                                                              .index_by(&:placement_id)
  end

  def molecule_cover_placement(atom)
    if atom.new_record? || (@atom_options && @atom_options[:console_preview])
      atom.cover_placement
    elsif @atom_options && @atom_options[:cover_placements]
      @atom_options[:cover_placements][atom.id]
    else
      molecule_cover_placements[atom.id]
    end
  end
end

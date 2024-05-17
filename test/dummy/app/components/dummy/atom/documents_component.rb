# frozen_string_literal: true

class Dummy::Atom::DocumentsComponent < ApplicationComponent
  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def render?
    @atom.document_placements.present?
  end

  def ui_documents_component
    Dummy::Ui::DocumentsComponent.new(document_placements: @atom.document_placements,
                                      size: @atom.size_with_fallback)
  end
end

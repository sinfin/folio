# frozen_string_literal: true

class Dummy::Molecule::Cards::FullWidthComponent < ApplicationComponent
  include Folio::Molecule::CoverPlacements

  THUMB_SIZE = "1920x1080#"

  def initialize(atoms:, atom_options: {})
    @atoms = atoms
    @atom_options = atom_options
  end

  def buttons_ary(atom)
    ary = []

    if atom.button_label.present? && atom.button_url.present?
      ary << { href: atom.button_url, label: atom.button_label }
    end

    if atom.secondary_button_label.present? && atom.secondary_button_url.present?
      ary << { href: atom.secondary_button_url,
               label: atom.secondary_button_label,
               variant: :secondary }
    end

    ary
  end

  def current_slide_index
    0
  end

  def data
    stimulus_controller("d-molecule-cards-full-width", values: { current_slide_index: })
  end

  def dot_target_data
    stimulus_data(target: :controlDot, action: { click: :onControlDotClick })
  end
end

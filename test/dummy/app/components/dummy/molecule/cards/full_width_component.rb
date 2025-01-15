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

    if atom.button_url_json.present?
      if atom.button_url_json[:label].present? && atom.button_url_json[:href].present?
        ary << {
          href: atom.button_url_json[:href],
          label: atom.button_url_json[:label],
          title: atom.button_url_json[:label],
          rel: atom.button_url_json[:rel],
          target: atom.button_url_json[:target],
        }
      end
    end

    if atom.button_url_json.present?
      if atom.button_url_json[:label].present? && atom.button_url_json[:href].present?
        ary << {
          href: atom.button_url_json[:href],
          label: atom.button_url_json[:label],
          title: atom.button_url_json[:label],
          rel: atom.button_url_json[:rel],
          target: atom.button_url_json[:target],
          variant: :secondary
        }
      end
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

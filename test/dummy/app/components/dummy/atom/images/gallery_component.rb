# frozen_string_literal: true

class Dummy::Atom::Images::GalleryComponent < ApplicationComponent
  TARGET_HEIGHT_DESKTOP = 350

  THUMB_MAX_WIDTH = 900
  THUMB_MAX_HEIGHT = 450
  THUMB_SIZE = "#{THUMB_MAX_WIDTH}x#{THUMB_MAX_HEIGHT}"

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def image_placements
    if @atom.persisted?
      @atom.image_placements.includes(:file)
    else
      @atom.image_placements
    end
  end

  def dynamic_item_data(image_placement)
    t = image_placement.file.thumb(THUMB_SIZE)

    ratio = t.width.to_f / t.height

    {
      ratio:,
      width: (TARGET_HEIGHT_DESKTOP * ratio).round,
    }
  end

  def data
    stimulus_controller("d-atom-images-gallery", Folio::StimulusHelper::LIGHTBOX_CONTROLLER,
                        values: {
                          target_height_desktop: TARGET_HEIGHT_DESKTOP,
                        })
  end
end

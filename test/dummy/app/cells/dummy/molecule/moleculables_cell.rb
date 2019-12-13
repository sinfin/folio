# frozen_string_literal: true

class Dummy::Molecule::MoleculablesCell < Folio::ApplicationCell
  include Folio::ImageHelper

  def cover(atom)
    if atom.cover_placement.present?
      lazy_image_from(atom.cover_placement,
                      Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE,
                      class: 'mw-100')
    end
  end
end

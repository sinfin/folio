# frozen_string_literal: true

class Dummy::Molecule::MoleculablesCell < Folio::ApplicationCell
  include Folio::ImageHelper

  def cover(atom)
    if atom.cover_placement.present?
      thumb(atom.cover_placement)
    end
  end

  def thumb(from)
    lazy_image_from(from,
                    Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE,
                    class: 'mw-100')
  end
end

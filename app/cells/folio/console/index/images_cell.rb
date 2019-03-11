# frozen_string_literal: true

class Folio::Console::Index::ImagesCell < Folio::ConsoleCell
  include Folio::CellLightbox

  def id_class_name
    # needed for separate lightboxes
    "f-c-index-images--id-#{model.class.table_name}-#{model.id}"
  end

  def show
    if options[:cover]
      render if model.cover.present?
    else
      render if model.images.present?
    end
  end

  def image(placement)
    image_from(placement,
               Folio::FileSerializer::ADMIN_THUMBNAIL_SIZE,
               lightbox(placement).merge(class: 'f-c-index-images__img'))
  end
end

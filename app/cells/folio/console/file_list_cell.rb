# frozen_string_literal: true

class Folio::Console::FileListCell < Folio::ConsoleCell
  include Folio::CellLightbox

  def show
    return nil if model.blank?
    render
  end

  def image_for(image)
    image_tag(image.thumb(Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE).url,
              lightbox_from_image(image).merge(
                class: 'folio-console-file-list__img',
              ))
  end

  def as_documents?
    model.any? { |file| !file.respond_to?(:thumb) }
  end
end

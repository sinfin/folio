# frozen_string_literal: true

class Folio::Console::Index::ImagesCell < Folio::ConsoleCell
  include Folio::CellLightbox

  class_name 'f-c-index-images', :cover, :gallery

  def id_class_name
    # needed for separate lightboxes
    if model.present?
      "f-c-index-images--id-#{model.class.table_name}-#{model.id}"
    end
  end

  def show
    if options[:cover] || options[:custom]
      render
    else
      render if model.image_placements.present?
    end
  end

  def gallery
    !options[:cover]
  end
end

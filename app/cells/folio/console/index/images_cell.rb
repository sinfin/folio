# frozen_string_literal: true

class Folio::Console::Index::ImagesCell < Folio::ConsoleCell
  include Folio::CellLightbox

  class_name "f-c-index-images", :cover, :gallery, :transparent

  def id_class_name
    # needed for separate lightboxes
    if model.present?
      "f-c-index-images--id-#{model.class.table_name}-#{model.id}"
    end
  end

  def show
    if options[:cover]
      render if model
    elsif options[:custom]
      render if model
    else
      render if model && model.image_placements.present?
    end
  end

  def gallery
    !options[:cover]
  end
end

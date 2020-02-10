# frozen_string_literal: true

class Folio::Console::FilePlacements::ListCell < Folio::ConsoleCell
  def show
    render if model.present?
  end

  def images?
    model && model.all? { |p| p.try(:file).is_a?(Folio::Image) }
  end

  def src(placement)
    placement.file
             .thumb(Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE)
             .url
  end
end

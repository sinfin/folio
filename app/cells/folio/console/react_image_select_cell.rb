# frozen_string_literal: true

class Folio::Console::ReactImageSelectCell < Folio::Console::ReactSelectCell
  BASE = :image

  def file_placements
    if options[:cover]
      f.object.cover_placement
    else
      f.object.file_placements.with_image
    end
  end

  def key
    if options[:cover]
      :cover_placement
    else
      :file_placements
    end
  end

  def exists
    if options[:cover]
      file_placements.present?
    else
      file_placements.exists?
    end
  end
end

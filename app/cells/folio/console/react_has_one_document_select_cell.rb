# frozen_string_literal: true

class Folio::Console::ReactHasOneDocumentSelectCell < Folio::Console::ReactSelectCell
  BASE = :document

  def file_placements
    f.object.send(key)
  end

  def key
    options[:key]
  end

  def exists
    file_placements.present?
  end

  def has_one?
    true
  end
end

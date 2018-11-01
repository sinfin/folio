# frozen_string_literal: true

class Folio::Console::ReactDocumentSelectCell < Folio::Console::ReactSelectCell
  BASE = :document

  def file_placements
    f.object.send(key).with_document
  end

  def key
    options[:key].presence || :file_placements
  end

  def exists
    file_placements.exists?
  end
end

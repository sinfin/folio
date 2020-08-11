# frozen_string_literal: true

class Dummy::Molecule::MoleculablesCell < Folio::ApplicationCell
  def size
    Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE
  end
end

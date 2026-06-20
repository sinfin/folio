# frozen_string_literal: true

class Folio::File::Document < Folio::File
  def thumbnailable?
    file_mime_type_image? || file_mime_type == "application/pdf"
  end
end

module Folio
  class Document < Folio::File
    paginates_per 16
  end
end

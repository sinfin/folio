# frozen_string_literal: true

module Folio
  class Document < Folio::File
    paginates_per 16
  end
end

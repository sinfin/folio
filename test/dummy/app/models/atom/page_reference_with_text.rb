# frozen_string_literal: true

module Atom
  class PageReferenceWithText < Folio::Atom::Base
    STRUCTURE = {
      content: :string,
      model: [Folio::Page],
    }
  end
end

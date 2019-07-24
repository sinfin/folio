# frozen_string_literal: true

module Atom
  class PageReferenceWithRichtext < Folio::Atom::Base
    STRUCTURE = {
      content: :richtext,
      model: %w[Folio::Page],
    }
  end
end

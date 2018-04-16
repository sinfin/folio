# frozen_string_literal: true

module Atom
  class PageReferenceWithRichtext < Folio::Atom::Base
    STRUCTURE = {
      content: :redactor,
      model: [Folio::Page],
    }
  end
end

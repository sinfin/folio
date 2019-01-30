# frozen_string_literal: true

module Atom
  class PageReferenceWithRichtext < Folio::Atom::Base
    STRUCTURE = {
      content: :redactor,
      model: %w[Folio::Page],
    }
  end
end

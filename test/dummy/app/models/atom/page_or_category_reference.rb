# frozen_string_literal: true

module Atom
  class PageOrCategoryReference < Folio::Atom::Base
    STRUCTURE = {
      model: [Folio::Page, Folio::Category],
    }
  end
end

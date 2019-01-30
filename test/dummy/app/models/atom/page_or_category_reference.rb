# frozen_string_literal: true

module Atom
  class PageOrCategoryReference < Folio::Atom::Base
    STRUCTURE = {
      model: %w[Folio::Page Folio::Category],
    }
  end
end

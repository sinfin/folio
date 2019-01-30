# frozen_string_literal: true

module Atom
  class PageReference < Folio::Atom::Base
    STRUCTURE = {
      model: %w[Folio::Page],
    }
  end
end

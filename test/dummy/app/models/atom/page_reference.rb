# frozen_string_literal: true

module Atom
  class PageReference < Folio::Atom::Base
    STRUCTURE = {
      model: Folio::Page,
    }
  end
end

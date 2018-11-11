# frozen_string_literal: true

module Atom
  class SingleDocument < Folio::Atom::Base
    STRUCTURE = {
      document: true,
    }

    validates :document_placement,
              presence: true
  end
end

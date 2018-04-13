# frozen_string_literal: true

module Atom
  class SingleDocument < Folio::Atom::Base
    STRUCTURE = {
      documents: :single,
    }
  end
end

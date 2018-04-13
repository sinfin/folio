# frozen_string_literal: true

module Atom
  class SingleImage < Folio::Atom::Base
    STRUCTURE = {
      images: :single,
    }
  end
end

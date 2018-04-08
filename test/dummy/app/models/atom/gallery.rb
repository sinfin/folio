# frozen_string_literal: true

module Atom
  class Gallery < Folio::Atom::Base
    STRUCTURE = {
      images: :multi,
    }
  end
end

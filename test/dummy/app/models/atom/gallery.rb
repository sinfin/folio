# frozen_string_literal: true

module Atom
  class Gallery < Folio::Atom::Base
    STRUCTURE = {
      images: true,
    }
  end
end

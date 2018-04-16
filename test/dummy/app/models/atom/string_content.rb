# frozen_string_literal: true

module Atom
  class StringContent < Folio::Atom::Base
    STRUCTURE = {
      content: :string,
    }
  end
end

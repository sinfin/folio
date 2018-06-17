# frozen_string_literal: true

module Atom
  class WithHint < Folio::Atom::Base
    STRUCTURE = {
      content: :string,
    }

    def self.form_hints
      { content: 'Custom hint' }
    end
  end
end

# frozen_string_literal: true

module Folio
  class Atom::PageReference < Atom
    ALLOWED_MODEL_TYPE = 'Folio::Page'

    def self.form
      :select
    end
  end
end

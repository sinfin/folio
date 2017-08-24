module Folio
  class Atom < ApplicationRecord
    # Relations
    belongs_to :node

    # Validations
    def self.types
      %w"Folio::Atom::Text Folio::Atom::Embedded"
    end
    validates :type, :content, presence: true
    validates :type, inclusion: { in: types }
  end
end

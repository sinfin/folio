# frozen_string_literal: true

module Folio
  class Atom < ApplicationRecord
    # Relations
    belongs_to :node

    # Validations
    validates :type, :content, presence: true
  end
end

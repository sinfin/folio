module Folio
  class MenuItem < ApplicationRecord
    # Relations
    has_ancestry orphan_strategy: :adopt
    belongs_to :menu, touch: true, required: true
    belongs_to :node, optional: true

    # Scopes
    scope :ordered, -> { order(position: :asc) }

    # Validations
    validates :title, presence: true

    def link
      node || rails_path
    end
  end
end

module Folio
  class Menu < ApplicationRecord
    # Relations
    has_many :menu_items
    accepts_nested_attributes_for :menu_items, allow_destroy: true,
                                                 reject_if: :all_blank

    # Validations
    validates :type, presence: true

    alias_attribute :items, :menu_items

    def title
      type
    end
  end
end

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

# == Schema Information
#
# Table name: folio_menus
#
#  id         :integer          not null, primary key
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_menus_on_type  (type)
#

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

# == Schema Information
#
# Table name: folio_menu_items
#
#  id         :integer          not null, primary key
#  menu_id    :integer
#  node_id    :integer
#  type       :string
#  ancestry   :string
#  title      :string
#  rails_path :string
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_menu_items_on_ancestry  (ancestry)
#  index_folio_menu_items_on_menu_id   (menu_id)
#  index_folio_menu_items_on_node_id   (node_id)
#  index_folio_menu_items_on_type      (type)
#

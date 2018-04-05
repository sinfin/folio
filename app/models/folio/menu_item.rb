# frozen_string_literal: true

module Folio
  class MenuItem < ApplicationRecord
    # Relations
    has_ancestry orphan_strategy: :adopt
    belongs_to :menu, touch: true, required: true
    belongs_to :target, optional: true, polymorphic: true

    # Scopes
    scope :ordered, -> { order(position: :asc) }

    # Validations
    validates :title, presence: true
    validate :validate_target_and_menu_locales

    private

      def validate_target_and_menu_locales
        if target && target.locale && target.locale != menu.locale
          errors.add(:target, :invalid)
        end
      end
  end
end

# == Schema Information
#
# Table name: folio_menu_items
#
#  id          :integer          not null, primary key
#  menu_id     :integer
#  type        :string
#  ancestry    :string
#  title       :string
#  rails_path  :string
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  target_type :string
#  target_id   :integer
#
# Indexes
#
#  index_folio_menu_items_on_ancestry                   (ancestry)
#  index_folio_menu_items_on_menu_id                    (menu_id)
#  index_folio_menu_items_on_target_type_and_target_id  (target_type,target_id)
#  index_folio_menu_items_on_type                       (type)
#

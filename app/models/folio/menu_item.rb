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
    validate :validate_target_and_menu_locales
    validate :validate_menu_allowed_types
    validate :validate_menu_available_targets_and_paths

    before_validation :nullify_empty_rails_path

    def to_label
      return title if title.present?
      return target.try(:title) || target.try(:to_label) if target.present?
      return menu.class.rails_paths[rails_path.to_sym] if rails_path.present?
      self.class.human_name
    end

    private

      def validate_target_and_menu_locales
        if target &&
           target.respond_to?(:locale) &&
           target.locale &&
           target.locale != menu.locale
          errors.add(:target, :invalid)
        end
      end

      def validate_menu_allowed_types
        if menu.class.allowed_menu_item_classes.exclude?(self.class)
          errors.add(:type, :invalid)
        end
      end

      def validate_menu_available_targets_and_paths
        if target && menu.available_targets.exclude?(target)
          errors.add(:target, :invalid)
        end
        if rails_path && menu.class.rails_paths.keys.exclude?(rails_path.to_sym)
          errors.add(:rails_path, :invalid)
        end
      end

      def nullify_empty_rails_path
        if rails_path.is_a?(String) && rails_path.blank?
          self.rails_path = nil
        end
      end
  end
end

if Rails.env.development?
  Dir["#{Folio::Engine.root}/app/models/folio/menu_item/*.rb",
      'app/models/menu_item/*.rb'].each do |file|
    require_dependency file
  end
end

# == Schema Information
#
# Table name: folio_menu_items
#
#  id          :bigint(8)        not null, primary key
#  menu_id     :bigint(8)
#  type        :string
#  ancestry    :string
#  title       :string
#  rails_path  :string
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  target_type :string
#  target_id   :bigint(8)
#
# Indexes
#
#  index_folio_menu_items_on_ancestry                   (ancestry)
#  index_folio_menu_items_on_menu_id                    (menu_id)
#  index_folio_menu_items_on_target_type_and_target_id  (target_type,target_id)
#  index_folio_menu_items_on_type                       (type)
#

# frozen_string_literal: true

module Folio
  class Menu < ApplicationRecord
    # Relations
    has_many :menu_items, -> { order(:position) }, dependent: :destroy
    accepts_nested_attributes_for :menu_items, allow_destroy: true,
                                               reject_if: :all_blank

    # Validations
    validates :type, :locale,
              presence: true

    alias_attribute :items, :menu_items

    def title
      model_name.human
    end

    def available_targets
      Node.where(locale: locale)
    end

    def supports_nesting?
      self.class.max_nesting_depth > 1
    end

    def self.rails_paths
      {}
    end

    def self.allowed_menu_item_classes
      MenuItem.recursive_subclasses
    end

    def self.allowed_menu_item_classes_for_select
      type_collection_for_select(self.allowed_menu_item_classes)
    end

    def self.max_nesting_depth
      1
    end
  end
end

if Rails.env.development?
  Dir["#{Folio::Engine.root}/app/models/folio/menu/*.rb", 'app/models/menu/*.rb'].each do |file|
    require_dependency file
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
#  locale     :string
#
# Indexes
#
#  index_folio_menus_on_type  (type)
#

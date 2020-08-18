# frozen_string_literal: true

class Folio::Menu < Folio::ApplicationRecord
  extend Folio::InheritenceBaseNaming
  include Folio::StiPreload

  # Relations
  has_many :menu_items, -> { ordered }, dependent: :destroy
  accepts_nested_attributes_for :menu_items, allow_destroy: true,
                                             reject_if: :all_blank

  # Validations
  validates :type, :locale,
            presence: true

  alias_attribute :items, :menu_items

  scope :ordered, -> { order(type: :asc, locale: :asc) }

  def title
    model_name.human
  end

  def available_targets
    if Rails.application.config.folio_using_traco ||
       !Rails.application.config.folio_pages_translations
      Folio::Page.all
    else
      Folio::Page.by_locale(locale)
    end
  end

  def supports_nesting?
    self.class.max_nesting_depth > 1
  end

  def self.rails_paths
    {}
  end

  def self.allowed_menu_item_classes
    Folio::MenuItem.recursive_subclasses
  end

  def self.allowed_menu_item_classes_for_select
    type_collection_for_select(self.allowed_menu_item_classes)
  end

  # Used for UI/controllers only
  # no model validations as that would get complex fast
  def self.max_nesting_depth
    1
  end

  def self.sti_paths
    [
      Folio::Engine.root.join("app/models/folio/menu"),
      Rails.root.join("app/models/**/menu"),
    ]
  end
end

# == Schema Information
#
# Table name: folio_menus
#
#  id         :bigint(8)        not null, primary key
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  locale     :string
#
# Indexes
#
#  index_folio_menus_on_type  (type)
#

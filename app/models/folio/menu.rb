# frozen_string_literal: true

class Folio::Menu < Folio::ApplicationRecord
  extend Folio::InheritenceBaseNaming
  include Folio::BelongsToSite
  include Folio::StiPreload

  # Relations
  has_many :menu_items, -> { ordered }, dependent: :destroy
  accepts_nested_attributes_for :menu_items, allow_destroy: true,
                                             reject_if: :all_blank

  # Validations
  validates :type, :locale,
            presence: true

  validates :title,
            presence: true,
            uniqueness: Rails.application.config.folio_site_is_a_singleton ? true : { scope: :site_id }

  alias_attribute :items, :menu_items
  before_validation :set_default_title

  scope :ordered, -> { order(type: :asc, locale: :asc) }

  scope :by_type, -> (type) do
    where(type:)
  end

  pg_search_scope :by_query,
                  against: {
                    title: "A",
                    type: "B",
                  },
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

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

  def self.styles
    []
  end

  def self.styles_for_react_select
    if self.styles.present?
      nil_ary = [[human_attribute_name("style/nil"), ""]]
      nil_ary + self.styles.without(:nil).map do |style|
        [
          human_attribute_name("style/#{style.nil? ? "nil" : style}"),
          style,
        ]
      end
    else
      []
    end
  end

  def self.rails_paths
    {}
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

  def self.creatable_types
    descendants.select do |klass|
      !klass.try(:singleton?)
    end
  end

  def self.creatable_types_for_select
    creatable_types.map do |klass|
      [klass.model_name.human, klass]
    end
  end

  private
    def set_default_title
      self.title ||= self.class.model_name.human
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
#  title      :string
#  site_id    :bigint(8)
#
# Indexes
#
#  index_folio_menus_on_site_id  (site_id)
#  index_folio_menus_on_type     (type)
#

# frozen_string_literal: true

class Folio::AttributeType < Folio::ApplicationRecord
  extend Folio::InheritenceBaseNaming
  include Folio::BelongsToSite
  include Folio::Positionable

  DATA_TYPES = %w[
    string
    integer
    float
  ]

  has_many :folio_attributes, class_name: "Folio::Attribute",
                              dependent: :destroy,
                              foreign_key: :folio_attribute_type_id

  validates :title,
            presence: true,
            uniqueness: { scope: %i[type site_id] }

  validates :type,
            presence: true

  validates :data_type,
            inclusion: { in: DATA_TYPES }

  def data_type_with_default
    data_type || DATA_TYPES.first
  end

  def self.human_data_types_name(data_type)
    human_attribute_name("data_types/#{data_type}")
  end

  def self.data_types_for_select(selectable_data_types = nil)
    DATA_TYPES.map do |data_type|
      [human_attribute_name("data_type/#{data_type}"), data_type]
    end
  end
end

# == Schema Information
#
# Table name: folio_attribute_types
#
#  id                     :bigint(8)        not null, primary key
#  site_id                :bigint(8)
#  title                  :string
#  type                   :string
#  position               :integer
#  data_type              :string           default("string")
#  folio_attributes_count :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_folio_attribute_types_on_folio_attributes_count  (folio_attributes_count)
#  index_folio_attribute_types_on_position                (position)
#  index_folio_attribute_types_on_site_id                 (site_id)
#  index_folio_attribute_types_on_type                    (type)
#

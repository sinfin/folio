# frozen_string_literal: true

class Folio::Attribute < Folio::ApplicationRecord
  belongs_to :folio_attribute_type, class_name: "Folio::AttributeType",
                                    inverse_of: :folio_attributes,
                                    counter_cache: :folio_attributes_count,
                                    foreign_key: :folio_attribute_type_id

  belongs_to :placement, polymorphic: true

  validates :value,
            presence: true

  scope :ordered, -> { joins(:folio_attribute_type).order("#{Folio::AttributeType.table_name}.position ASC") }

  if Rails.application.config.folio_using_traco
    translates :value
  end

  def to_label
    value
  end

  def value_type
    folio_attribute_type.data_type
  end
end

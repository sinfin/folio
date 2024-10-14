# frozen_string_literal: true

# Use when model need some adhoc attributes, and You do not want them as columns in DB
# This adds folio_attributes association to model
# Then You have to add records to folio_attribute_types table (templates/types of attributes)
# And finally use such types to set actual values for instances of models
module Folio::HasFolioAttributes
  extend ActiveSupport::Concern

  class_methods do
    def has_folio_attributes(*types)
      has_many :folio_attributes, -> { ordered },
                                  class_name: "Folio::Attribute",
                                  dependent: :destroy,
                                  inverse_of: :placement

      accepts_nested_attributes_for :folio_attributes, reject_if: :all_blank, allow_destroy: true

      define_method :folio_attribute_types do
        types
      end
    end
  end
end

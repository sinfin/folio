# frozen_string_literal: true

module Folio::HasAddresses
  extend ActiveSupport::Concern

  included do
    belongs_to :primary_address, class_name: "Folio::Address::Primary",
                                  foreign_key: :primary_address_id,
                                  optional: true

    belongs_to :secondary_address, class_name: "Folio::Address::Secondary",
                                   foreign_key: :secondary_address_id,
                                   optional: true

    %i[primary_address secondary_address].each do |key|
      accepts_nested_attributes_for key,
                                    allow_destroy: true,
                                    reject_if: -> (attributes) {
                                      send("reject_#{key}_attributes?", attributes)
                                    }

      validates key,
                presence: true,
                if: "should_validate_#{key}?".to_sym
    end

    before_validation :unset_unwanted_secondary_address
  end

  module ClassMethods
    def reject_address_attributes?(attributes)
      attributes.with_indifferent_access
                .except(:country_code)
                .values
                .all?(&:blank?)
    end

    def reject_primary_address_attributes?(attributes)
      !self.new.send(:should_validate_primary_address?) && reject_address_attributes?(attributes)
    end

    def reject_secondary_address_attributes?(attributes)
      !self.new.send(:should_validate_secondary_address?) && reject_address_attributes?(attributes)
    end
  end

  private
    def unset_unwanted_secondary_address
      if use_secondary_address == false && secondary_address.present?
        secondary_address.mark_for_destruction
      end
    end

    def should_validate_address?
      false
    end

    def should_validate_secondary_address?
      use_secondary_address ? should_validate_address? : false
    end

    def should_validate_primary_address?
      should_validate_address?
    end
end

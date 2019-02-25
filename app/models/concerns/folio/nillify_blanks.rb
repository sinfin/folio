# frozen_string_literal: true

module Folio::NillifyBlanks
  extend ActiveSupport::Concern

  included do
    before_validation :nillify_blanks
  end

  class_methods do
    def non_nillifiable_fields
      []
    end
  end

  private

    def nillify_blanks
      attributes.each do |column, value|
        next if self.class.non_nillifiable_fields.include?(column)
        if value.blank? && !value.nil? && value != false
          self[column] = nil
        end
      end
    end
end

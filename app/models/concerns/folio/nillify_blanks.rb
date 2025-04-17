# frozen_string_literal: true

module Folio::NillifyBlanks
  extend ActiveSupport::Concern

  included do
    class_attribute :skipped_nillify_attributes, default: [], instance_writer: false

    before_validation :nillify_blanks
  end

  class_methods do
    # You can specify exceptions by this method. Needed for json columns with default {}.
    # example:
    #   skip_nillify_for :metadata
    def skip_nillify_for(*fields)
      self.skipped_nillify_attributes = (self.skipped_nillify_attributes + fields.compact.map(&:to_s)).uniq
    end
  end

  def nillify_blanks
    attributes.each do |column, value|
      default_value = self.class.column_for_attribute(column).default

      next if self.class.skipped_nillify_attributes.include?(column)
      if value.blank? && default_value.nil? && !value.nil? && value != false
        self[column] = nil
      end
    end
  end
end

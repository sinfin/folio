# frozen_string_literal: true

module Folio::NillifyBlanks
  extend ActiveSupport::Concern

  included do
    class_attribute :skipped_nillify_attributes, default: [], instance_writer: false

    before_validation :nillify_blanks
  end

  class_methods do
    # TODO: I think it's not needed. I did not find any attribute with this name anywhere
    # def non_nillifiable_fields
    #   %w[ancestry_url]
    # end

    # You can specify exceptions by this method. Needed for json columns with default {}.
    # example:
    #   skip_nillify_for :metadata
    def skip_nillify_for(*fields)
      self.skipped_nillify_attributes = (self.skipped_nillify_attributes + fields.compact.map(&:to_s)).uniq
    end
  end

  def nillify_blanks
    attributes.each do |column, value|
      # next if self.class.non_nillifiable_fields.include?(column)
      next if self.class.skipped_nillify_attributes.include?(column)
      if value.blank? && !value.nil? && value != false
        self[column] = nil
      end
    end
  end
end

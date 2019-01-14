# frozen_string_literal: true

module Folio::NillifyBlanks
  extend ActiveSupport::Concern

  included do
    before_validation :nillify_blanks
  end

  private

    def nillify_blanks
      attributes.each do |column, value|
        if value.blank? && !value.nil? && value != false
          self[column] = nil
        end
      end
    end
end

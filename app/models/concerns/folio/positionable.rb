# frozen_string_literal: true

module Folio
  module Positionable
    extend ActiveSupport::Concern

    included do
      # Validations
      validates :position, presence: true

      # Scopes
      scope :ordered,   -> { order('position asc, created_at desc') }

      # Callbacks
      before_validation :set_position
    end

    private
      def set_position
        if self.position.nil?
          last = self.class.ordered.last
          self.position = !last.nil? ? last.position + 1 : 0
        end
      end
  end
end

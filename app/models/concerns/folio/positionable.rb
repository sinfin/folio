# frozen_string_literal: true

module Folio
  module Positionable
    extend ActiveSupport::Concern

    included do
      # Validations
      validates :position, presence: true

      # Scopes
      scope :ordered, -> { order(position: :asc, created_at: :desc) }

      # Callbacks
      before_validation :set_position
    end

    private
      def set_position
        if self.position.nil?
          last_record = self.class.ordered.last

          if last_record.present?
            last_position = last_record.position.presence || 0
          else
            last_position = 0
          end

          self.position = last_position + 1
        end
      end
  end
end

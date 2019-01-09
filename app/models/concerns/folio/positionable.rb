# frozen_string_literal: true

module Folio::Positionable
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
        self.position = positionable_last_position + 1
      end
    end

    def positionable_last_position
      if positionable_last_record.present?
        last_position = positionable_last_record.position.presence || 0
      else
        last_position = 0
      end
    end

    def positionable_last_record
      self.class.ordered.last
    end
end

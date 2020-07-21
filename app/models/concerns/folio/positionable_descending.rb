# frozen_string_literal: true

module Folio::PositionableDescending
  extend ActiveSupport::Concern

  included do
    # Validations
    validates :position, presence: true

    # Scopes
    scope :ordered, -> { order(position: :desc) }

    # Callbacks
    before_validation :set_position
  end

  class_methods do
    def positionable_descending?
      true
    end
  end

  private
    def set_position
      if self.position.nil?
        self.position = positionable_last_position + 1
      end
    end

    def positionable_last_position
      if positionable_last_record.present?
        positionable_last_record.position.presence || 0
      else
        0
      end
    end

    def positionable_last_record
      self.class.ordered.first
    end
end

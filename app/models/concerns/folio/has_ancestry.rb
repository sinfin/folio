# frozen_string_literal: true

module Folio::HasAncestry
  extend ActiveSupport::Concern

  included do
    has_ancestry touch: true

    validate :validate_allowed_type,
             if: :has_parent?

    before_save :set_position
  end

  class_methods do
    def arrange_as_array(options = {}, hash = nil)
      hash ||= arrange(options)
      arr = []

      hash.each do |page, children|
        arr << page
        arr += arrange_as_array(options, children) unless children.empty?
      end

      arr
    end

    def allowed_child_types
      nil
    end
  end

  def select_option_depth
    "#{'&nbsp;' * self.depth} #{self.to_label}".html_safe
  end

  private
    def validate_allowed_type
      return if parent.nil? || parent.class.try(:allowed_child_types).nil?

      if parent.class.allowed_child_types.exclude? self.class
        errors.add(:type, 'is not allowed')
      end
    end

    def set_position
      if self.position.nil?
        last = self.siblings.ordered.last
        self.position = !last.nil? ? last.position + 1 : 0
      end
    end
end

# frozen_string_literal: true

module Folio::Transportable::Model
  extend ActiveSupport::Concern

  def transportable?
    true
  end

  def transportable_attributes_default
    self.class.column_names.map(&:to_sym)
  end

  def transportable_attributes
    transportable_attributes_default
  end

  def transportable_associations
    {}
  end

  class_methods do
    def transportable?
      true
    end
  end
end

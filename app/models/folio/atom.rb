# frozen_string_literal: true

module Folio
  class Atom < ApplicationRecord
    include HasAttachments

    # override in subclasses
    ALLOWED_MODEL_TYPE = nil

    before_validation do
      write_attribute(:model_type, 'Artworx::Item') if model_type.nil?
    end

    belongs_to :placement, polymorphic: true
    alias_attribute :node, :placement
    belongs_to :model, polymorphic: true, optional: true

    accepts_nested_attributes_for :model, allow_destroy: true

    validate :model_type_is_allowed, if: :model_id?

    scope :ordered, -> { order(position: :asc) }

    def cell_name
      nil
    end

    def partial_name
      model_name.element
    end

    def data
      self
    end

    # override in subclasses
    def self.form
      false
    end

    # def model_type
    #   self.class::ALLOWED_MODEL_TYPE
    # end

    def resource_for_select
      if self.class::ALLOWED_MODEL_TYPE
        scopes_for_select_options Object.const_get(self.class::ALLOWED_MODEL_TYPE).all
      end
    end

    # override in subclasses
    def scopes_for_select_options(resource)
      resource
    end

    private
      def model_type_is_allowed
        if model_type != self.class::ALLOWED_MODEL_TYPE
          errors.add(:model, 'associated model class not allowed')
        end
      end
  end
end

if Rails.env.development?
  Dir["#{Folio::Engine.root}/app/models/folio/atom/*.rb", 'app/models/atom/*.rb'].each do |file|
    require_dependency file
  end
end

# == Schema Information
#
# Table name: folio_atoms
#
#  id             :integer          not null, primary key
#  type           :string
#  content        :text
#  position       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  placement_type :string
#  placement_id   :integer
#
# Indexes
#
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#

# frozen_string_literal: true

module Folio
  module Atom
    class Base < ApplicationRecord
      include HasAttachments

      # hash consisting of :content, :title, :images, :model
      STRUCTURE = {
        content: nil, # one of nil, :string, :redactor
        title: nil,   # one of nil, :string
        images: nil,  # one of nil, :single, :multi
        model: nil,   # nil or a model class
      }

      self.table_name = 'folio_atoms'

      before_validation do
        if model_type.nil? && self.class::STRUCTURE[:model].present?
          write_attribute(:model_type, self.class::STRUCTURE[:model])
        end
      end

      belongs_to :placement,
                 polymorphic: true,
                 touch: true,
                 # so that validations work https://stackoverflow.com/a/39114379/910868
                 optional: true
      alias_attribute :node, :placement
      belongs_to :model, polymorphic: true, optional: true

      accepts_nested_attributes_for :model, allow_destroy: true

      validate :model_type_is_allowed, if: :model_id?

      scope :ordered, -> { order(position: :asc) }
      scope :by_type, -> (type) { where(type: type.to_s) }

      def cell_name
        nil
      end

      def cell_options
        nil
      end

      def partial_name
        model_name.element
      end

      def data
        self
      end

      def self.resource_for_select
        return nil if self::STRUCTURE[:model].blank?
        self::STRUCTURE[:model].all
      end

      # override in subclasses
      def self.scopes_for_select_options(resource)
        resource
      end

      def self.structure_as_json
        self::STRUCTURE.dup.tap do |structure|
          if structure[:model].present?
            structure[:model] = structure[:model].to_s
          end
        end.to_json
      end

      private

        def model_type_is_allowed
          if model && model.class != self.class::STRUCTURE[:model]
            errors.add(:model_type, :invalid)
          end
        end
    end
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
#  model_type     :string
#  model_id       :integer
#  title          :string
#
# Indexes
#
#  index_folio_atoms_on_model_type_and_model_id          (model_type,model_id)
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#

# frozen_string_literal: true

module Folio
  module Atom
    class Base < ApplicationRecord
      include HasAttachments
      include PgSearch

      self.table_name = 'folio_atoms'

      # override in subclasses
      ALLOWED_MODEL_TYPE = nil

      before_validation do
        if model_type.nil? && self.class::ALLOWED_MODEL_TYPE.present?
          write_attribute(:model_type, self.class::ALLOWED_MODEL_TYPE)
        end
      end

      belongs_to :placement,
                 polymorphic: true,
                 # so that validations work https://stackoverflow.com/a/39114379/910868
                 optional: true
      alias_attribute :node, :placement
      belongs_to :model, polymorphic: true, optional: true

      accepts_nested_attributes_for :model, allow_destroy: true

      validate :model_type_is_allowed, if: :model_id?

      scope :ordered, -> { order(position: :asc) }
      scope :by_type, -> (type) { where(type: type.to_s) }

      multisearchable against: [ :title, :content ],
                      if: :searchable?,
                      ignoring: :accents

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

      # override in subclasses
      def self.form
        false
      end

      def resource_for_select
        if self.class::ALLOWED_MODEL_TYPE
          scopes_for_select_options Object.const_get(self.class::ALLOWED_MODEL_TYPE).all
        end
      end

      # override in subclasses
      def scopes_for_select_options(resource)
        resource
      end

      def searchable?
        placement && placement.searchable?
      end

      private

        def model_type_is_allowed
          if model_type != self.class::ALLOWED_MODEL_TYPE
            errors.add(:model, 'associated model class not allowed')
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

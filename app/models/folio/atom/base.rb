# frozen_string_literal: true

module Folio
  module Atom
    class Base < ApplicationRecord
      include HasAttachments
      include Positionable

      STRUCTURE = {
        content: nil,   # one of nil, :string, :redactor
        title: nil,     # one of nil, :string
        images: nil,    # one of nil, :single, :multi
        documents: nil, # one of nil, :single, :multi
        model: nil,     # nil or an array of model classes
      }

      self.table_name = 'folio_atoms'

      before_save :unset_extra_attrs, if: :type_changed?
      after_save :unlink_extra_files, if: :saved_change_to_type?

      belongs_to :placement,
                 polymorphic: true,
                 touch: true,
                 # so that validations work https://stackoverflow.com/a/39114379/910868
                 optional: true
      alias_attribute :node, :placement
      belongs_to :model, polymorphic: true, optional: true

      accepts_nested_attributes_for :model, allow_destroy: true

      validate :model_type_is_allowed, if: :model_id?

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

      def document
        documents.first if klass::STRUCTURE[:documents] === :single
      end

      def self.scoped_model_resource(resource)
        resource.all
      end

      def self.structure_as_json
        self::STRUCTURE.dup.tap do |structure|
          if structure[:model].present?
            structure[:model] = structure[:model].to_s
          end
        end.to_json
      end

      def self.molecule
        nil
      end

      def self.molecule_cell_name
        molecule.try(:cell_name)
      end

      def self.form_hints
        {
          title: nil,
          content: nil,
        }
      end

      private

        def klass
          # as type can be changed
          self.type.constantize
        end

        def model_type_is_allowed
          if model &&
             klass::STRUCTURE[:model].present? &&
             klass::STRUCTURE[:model].none? { |m| model.is_a?(m) }
            errors.add(:model_type, :invalid)
          end
        end

        def unset_extra_attrs
          if klass::STRUCTURE[:model].blank? && model.present?
            self.model_id = nil
            self.model_type = nil
          end

          if klass::STRUCTURE[:title].blank? && title.present?
            self.title = nil
          end

          if klass::STRUCTURE[:content].blank? && content.present?
            self.content = nil
          end
        end

        def unlink_extra_files
          if klass::STRUCTURE[:images] != :single
            self.cover_placement.destroy! if cover_placement.present?
          end

          if klass::STRUCTURE[:images] != :multi
            if file_placements.with_image.exists?
              self.file_placements.with_image.each(&:destroy!)
            end
          end

          if klass::STRUCTURE[:documents].nil?
            if file_placements.with_document.exists?
              self.file_placements.with_document.each(&:destroy!)
            end
          end
        end

        def set_position
          if self.position.nil? && self.placement.present?
            last_atom = self.placement.reload.atoms.last

            if last_atom.present?
              last_position = last_atom.position.presence || 0
            else
              last_position = 0
            end

            self.position = last_position + 1
          else
            super
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

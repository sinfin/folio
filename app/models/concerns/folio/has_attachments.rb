# frozen_string_literal: true

module Folio
  module HasAttachments
    extend ActiveSupport::Concern

    included do
      has_many :file_placements, class_name: 'Folio::FilePlacement::Base',
                                 as: :placement,
                                 dependent: :destroy

      has_many :files,
               source: :file,
               class_name: 'Folio::File',
               through: :file_placements

      has_many_placements(:images,
                          :image_placements,
                          class_name: 'Folio::Image',
                          placement: 'Folio::FilePlacement::Image')

      has_many_placements(:documents,
                          :document_placements,
                          class_name: 'Folio::Document',
                          placement: 'Folio::FilePlacement::Document')

      has_one_placement(:cover,
                        :cover_placement,
                        class_name: 'Folio::Image',
                        placement: 'Folio::FilePlacement::Cover')

      has_one_placement(:document,
                        :single_document_placement,
                        class_name: 'Folio::Document',
                        placement: 'Folio::FilePlacement::SingleDocument')
    end

    class_methods do
      def has_many_placements(targets, placements_key, class_name:, placement:)
        has_many placements_key,
                 class_name: placement,
                 as: :placement,
                 inverse_of: :placement,
                 dependent: :destroy,
                 foreign_key: :placement_id

        has_many targets,
                 source: :file,
                 class_name: class_name,
                 through: placements_key

        accepts_nested_attributes_for placements_key, allow_destroy: true
      end

      def has_one_placement(target, placement_key, class_name:, placement:)
        has_one placement_key,
                class_name: placement,
                as: :placement,
                inverse_of: :placement,
                dependent: :destroy,
                foreign_key: :placement_id

        has_one target,
                source: :file,
                class_name: class_name,
                through: placement_key

        accepts_nested_attributes_for placement_key, allow_destroy: true
      end
    end
  end
end

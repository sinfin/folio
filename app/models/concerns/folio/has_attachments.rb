# frozen_string_literal: true

module Folio
  module HasAttachments
    extend ActiveSupport::Concern

    included do
      has_many :file_placements, -> { ordered },
                                 class_name: 'Folio::FilePlacement',
                                 as: :placement,
                                 dependent: :destroy

      has_many :files, -> { order('folio_file_placements.position ASC') },
                       through: :file_placements

      has_many :images, -> { order('folio_file_placements.position ASC') },
                        source: :file,
                        class_name: 'Folio::Image',
                        through: :file_placements

      has_many :documents, -> { order('folio_file_placements.position ASC') },
                           source: :file,
                           class_name: 'Folio::Document',
                           through: :file_placements

      has_one :cover_placement, class_name: 'Folio::CoverPlacement',
                                as: :placement,
                                dependent: :destroy

      has_one :cover, source: :file, through: :cover_placement

      accepts_nested_attributes_for :file_placements, allow_destroy: true
      accepts_nested_attributes_for :cover_placement, allow_destroy: true

      scope :with_cover, -> { joins(:cover) }
      scope :with_images, -> { joins(:images) }
      scope :with_documents, -> { joins(:documents) }
    end
  end
end

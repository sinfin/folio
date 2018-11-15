# frozen_string_literal: true

module Folio
  class FilePlacement::Base < ApplicationRecord
    include Taggable

    self.table_name = 'folio_file_placements'

    scope :ordered, -> { order(position: :asc) }

    validates :type,
              presence: true

    def to_label
      title.presence || file.file_name
    end

    def self.folio_file_placement(class_name, name = nil)
      belongs_to :file, class_name: class_name,
                        inverse_of: :file_placements,
                        required: true

      belongs_to :placement, polymorphic: true,
                             inverse_of: name,
                             required: true,
                             touch: true
    end

    def self.folio_image_placement(name = nil)
      include PregenerateThumbnails
      folio_file_placement('Folio::Image', name)
      self.class_eval { alias :image :file }
    end

    def self.folio_document_placement(name = nil)
      folio_file_placement('Folio::Document', name)
    end
  end
end

# == Schema Information
#
# Table name: folio_file_placements
#
#  id             :bigint(8)        not null, primary key
#  placement_type :string
#  placement_id   :bigint(8)
#  file_id        :bigint(8)
#  position       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  type           :string
#  title          :text
#  alt            :string
#
# Indexes
#
#  index_folio_file_placements_on_file_id                          (file_id)
#  index_folio_file_placements_on_placement_type_and_placement_id  (placement_type,placement_id)
#  index_folio_file_placements_on_type                             (type)
#

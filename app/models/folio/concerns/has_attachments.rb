# frozen_string_literal: true

module Folio
  module HasAttachments
    extend ActiveSupport::Concern

    included do
      has_many :file_placements, -> { ordered }, class_name: 'Folio::FilePlacement', as: :placement, dependent: :destroy
      has_many :files, through: :file_placements
      has_many :images, source: :file, class_name: 'Folio::Image', through: :file_placements
      has_many :documents, source: :file, class_name: 'Folio::Document', through: :file_placements
      
      accepts_nested_attributes_for :file_placements, allow_destroy: true

      scope :by_tag, -> (tag) { tagged_with(tag) }
    end
  end
end

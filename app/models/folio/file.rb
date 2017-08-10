module Folio
  class File < ApplicationRecord
    dragonfly_accessor :file

    # Relations
    has_many :file_placements, class_name: 'Folio::FilePlacement'

    # Validations
    def self.types
      %w"Folio::Image Folio::Document"
    end
    validates :file, :type, presence: true
    validates :type, inclusion: { in: types }

    def title
      file_name
    end
  end
end

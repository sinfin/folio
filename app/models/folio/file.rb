module Folio
  class File < ApplicationRecord
    dragonfly_accessor :file

    # Relations
    has_many :file_placements, class_name: 'Folio::FilePlacement'

    # Validations
    validates :file, presence: true

    def title
      file_name
    end
  end
end

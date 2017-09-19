# frozen_string_literal: true

require_dependency 'folio/concerns/taggable'

module Folio
  class File < ApplicationRecord
    include Taggable

    dragonfly_accessor :file

    # Relations
    has_many :file_placements, class_name: 'Folio::FilePlacement'

    # Validations
    validates :file, :type, presence: true

    def title
      file_name
    end
  end
end

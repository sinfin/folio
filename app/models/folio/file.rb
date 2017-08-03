module Folio
  class File < ApplicationRecord
    dragonfly_accessor :file
    validates :file, presence: true

    def title
      file_name
    end
  end
end
